(use /environment /schema)
(import twm/symbiont :as symbiont)
(import gp/net/rpc)

(def- recordings
  ```
  The recordings made, by id, as the tree last accepted them.

  Kept beside the state, like the decker's builds. The tree holds the
  truth; this only spares asking it for every deck at every slide.
  ```
  @{})

(def- plain
  "Elements a slide is made of that keep no attributes."
  [:section :h1 :h2 :h3 :h4 :h5 :h6 :p :ul :ol :li :blockquote :pre :strong :em])

(def- language (peg/compile ~(* "language-" (some (+ :w (set "+-#."))) -1)))

(defn- web?
  [url]
  (and (string? url)
       (or (string/has-prefix? "https://" url) (string/has-prefix? "http://" url))))

(defn- attributes
  "What of the attributes `given` a `tag` of a recorded slide keeps, or nil."
  [tag given]
  (case tag
    :a (if (web? (given :href)) {:href (given :href) :target "_blank" :rel "noopener"})
    :img (if (web? (given :src))
           {:src (given :src) :alt (if (string? (given :alt)) (given :alt) "")})
    :code (if (and (string? (given :class)) (peg/match language (given :class)))
            {:class (given :class)})))

(defn slide/clean
  ```
  `node` with nothing left in it but what the parser itself makes of a
  deck: text, and a slide's elements with their few attributes.

  A recorded slide comes from another thicket and is shown in the
  lecturer's own page, behind the password. A script, a handler or a
  `javascript:` address would run there, so none gets through, and neither
  does anything that is not plain data. A link to anywhere else is left as
  its text, and an image from anywhere else is left out.
  ```
  [node]
  (cond
    (or (string? node) (buffer? node)) (string node)
    (number? node) (string node)
    (and (indexed? node) (keyword? (get node 0)))
    (let [tag (node 0)
          given (if (dictionary? (get node 1)) (node 1))
          children (drop (if given 2 1) node)
          kept (filter truthy? (map slide/clean children))
          attrs (attributes tag (or given {}))]
      (cond
        (= :img tag) (if attrs [:img attrs])
        (= :a tag) (if attrs [:a attrs ;kept] [:span ;kept])
        (= :code tag) (if attrs [:code attrs ;kept] [:code ;kept])
        (index-of tag plain) [tag ;kept]))))

(defn recording/id
  ```
  The id of the recording of the deck `presentation` followed from `from`.
  One deck is one recording, lecture after lecture.
  ```
  [from presentation]
  (->> (string from "--" presentation)
       (string/replace-all "/" "-")
       (string/replace-all "\\" "-")))

(defn- sections/of
  "The sections of a recording, from the part each of its slides said it was in."
  [parts]
  (def sections @[])
  (eachp [i part] parts
    (def current (last sections))
    (if (and current (= (current :title) (part :section)))
      (update current :count inc)
      (array/push sections @{:title (part :section) :author (part :author)
                             :date (part :date) :first i :count 1})))
  sections)

(defn recorded
  ```
  The recording `deck` -- nil for one not begun -- with the `slide` that
  `live`, followed from `from`, shows; nil when it holds that slide already.

  Slides keep the order they have in the lecturer's deck, whatever order
  they were shown in, and one shown again as the lecturer changed it takes
  the place of the one shown before.
  ```
  [deck from live slide]
  (def at (array ;(get-in deck [:recorded :at] [])))
  (def slides (array ;(get deck :slides [])))
  (def parts (array ;(get-in deck [:recorded :parts] [])))
  (def n (live :slide))
  (def part {:section (live :section) :author (live :author) :date (live :date)})
  (def i (or (find-index |(>= $ n) at) (length at)))
  (unless (and (= n (get at i)) (deep= slide (get slides i)))
    (if (= n (get at i))
      (do (put slides i slide) (put parts i part))
      (do (array/insert at i n) (array/insert slides i slide) (array/insert parts i part)))
    @{:title (live :title)
      :slides slides
      :sections (sections/of parts)
      :recorded @{:from from :presentation (live :presentation) :count (live :count)
                  :at at :parts parts}}))

(defn- record
  "Records what `live`, followed from `from`, shows, and tells the tree what is attended."
  [tree from live]
  (def slide (if (and live (live :content)) (slide/clean (live :content))))
  (if (slide? slide)
    (let [id (recording/id from (live :presentation))
          held (or (recordings id) (get (:presentations tree) id))
          deck (recorded held from live slide)]
      (when deck
        (put deck :modified (os/time))
        (:save-presentation tree id deck)
        (put recordings id deck))
      (:attending/set tree from
                      {:title (live :title) :presentation id
                       :slide (index-of (live :slide) (get-in (or deck held) [:recorded :at]))}))
    (:attending/set tree from (if (and live (present-string? (live :title)))
                                {:title (live :title)}
                                false))))

(defn ^relay/follow
  ```
  Follows the relay `from`, at `:rpc` and known by its public `:key`, for
  as long as the recorder lives: every slide it shows is recorded.

  A relay that cannot be reached, or will not admit this thicket, is tried
  again a little later, and meanwhile nothing is attended from it.
  ```
  [from {:rpc url :key key}]
  (make-watch
    (fn [_ state _]
      (def {:tree tree :name name :identity identity} state)
      (def [host port] (server/host-port url))
      (producer
        (produce (log name " follows " from " at " url))
        (var relay nil)
        (var mark nil)
        (forever
          (match (protect
                   (unless relay
                     (set relay (rpc/client host port
                                            (string "recorder " (string/slice (identity :public) 0 16))
                                            relay/psk
                                            :keypair (identity/keypair identity)
                                            :server-key (key/bin key)))
                     (put relay :timeout (+ relay/wait 10)))
                   (:live/after relay mark))
            [true answer]
            (do (set mark (get answer :mark))
              (match (protect (record tree from (get answer :live)))
                [false err] (produce (log name " could not record from " from ": " err)))
              # An answer with nothing to ask after would be asked again at
              # once, and again.
              (unless mark (ev/sleep 1)))
            [false err]
            (do (produce (log name " cannot follow " from ": " err))
              (when relay (protect (:close relay)))
              (set relay nil)
              (set mark nil)
              (protect (:attending/set tree from false))
              (ev/sleep 10))))))
    (. "follow " from)))

(define-watch Start
  "Starts RPC, announces readiness, and follows every relay the recorder holds a key for."
  [_ state _]
  (def follows (get state :follows {}))
  (assert (or (empty? follows) (identity? (state :identity)))
          "The recorder needs an :identity to be known by")
  [(^rpc/start [AetherReady ;(seq [[from relay] :pairs follows] (^relay/follow from relay))])])

(def initial-state
  "Initial state"
  ((>update :rpc (update-rpc @{})) compile-config))

(symbiont/main initial-state Start)
