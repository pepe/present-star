(use /environment /schema)
(import twm/tree :as twm-tree)
(import twm/delivery)

(setdyn *rpc-defines* [:view])

(def collections/stored
  "What the tree keeps in its image: the decks and where the stage is."
  [:presentations :stage])

(def collections/projected
  "Collections a peer may ask the tree to project in one snapshot."
  [:cap/session :presentations :errors :stage :live])

(defn- revise
  ```
  Moves the view to its next revision, and returns the view.

  A snapshot says which revision it saw, so whoever holds one can tell it
  from an older one. Whatever changes what a snapshot would say moves it.
  ```
  [view]
  (put view :projection/revision (inc (get view :projection/revision 0))))

(defn live/of
  ```
  The shadow a watcher is given: the slide on the stage, and nothing of
  the deck beyond it.

  A watcher is a cosymbiont. It follows the lecture and needs no more than
  what the lecturer has shown; holding the rest of the deck would put the
  next slides a view-source away from every student.
  ```
  [presentations stage]
  (when-let [{:presentation id :slide n} stage
             deck (get presentations id)]
    (def section (or (section/at deck n) {}))
    {:presentation id
     :title (deck :title)
     :section (section :title)
     :author (get section :author (deck :author))
     :date (get section :date (deck :date))
     :slide n
     :count (length (deck :slides))
     :content (get-in deck [:slides n])}))

(defn stage/moved
  ```
  Where `move` takes `stage` among `presentations`, as `[:ok stage]`, or
  `[:refused reason]`.

  Slides are counted from zero and a move never leaves the deck: the next
  slide after the last is the last. Going past the end is what a clicker
  does when a lecturer presses once too often, and it is not an error.
  ```
  [presentations stage move]
  (defn last-of [id] (max 0 (dec (length (get-in presentations [id :slides] [])))))
  (defn at [id n] {:presentation id :slide (min (max 0 n) (last-of id))})
  (match [(length move) ;move]
    [2 :start id] (if (presentations id)
                    [:ok (at id 0)]
                    [:refused (. "There is no presentation " id ".")])
    [3 :goto id n] (if (presentations id)
                     [:ok (at id n)]
                     [:refused (. "There is no presentation " id ".")])
    [1 :next] (if stage
                [:ok (at (stage :presentation) (inc (stage :slide)))]
                [:refused "Nothing is presented."])
    [1 :previous] (if stage
                    [:ok (at (stage :presentation) (dec (stage :slide)))]
                    [:refused "Nothing is presented."])
    [1 :stop] [:ok nil]
    [:refused "Unknown move."]))

(define-update RefreshView
  ```
  Rebuilds the view from the store.

  An empty stage is `false`, never nil. A snapshot carries its values in a
  table, and a table cannot hold nil: an emptied stage would simply be
  missing from it, and every peer would go on showing the last slide.
  ```
  [_ {:view view :store store}]
  (def presentations (or (:load store :presentations) @{}))
  (def stage (:load store :stage))
  (put view :presentations presentations)
  (put view :stage (or stage false))
  (put view :live (or (live/of presentations stage) false))
  (revise view))

(defn ^push
  ```
  Tells every registered peer that `topics` changed.

  Only peers the tree holds a client for: one that has not registered, or
  has said goodbye, has nobody at its address to tell. The telling goes
  through delivery, which coalesces and retries outside this manager, so a
  slow presenter never holds up a slide on its way to the watchers.
  ```
  [& topics]
  (make-watch
    (fn [_ state _]
      (seq [peer :in (state :peers) :when (table? (state peer))]
        (delivery/^invalidate peer ;topics)))
    (. "push " (string/join (map string topics) " "))))

(defn- staged?
  [store id]
  (= id (get (:load store :stage) :presentation)))

(defn ^save-presentation
  ```
  Keeps the deck `id` as the decker built it, and forgets its last error.

  A deck rebuilt while it is on the stage may have lost the slide being
  shown; the stage then stands on its new last slide rather than on
  nothing.
  ```
  [id deck]
  (var live false)
  (make-event
    {:update
     (fn [_ {:store store :view view}]
       (:save store deck :presentations id)
       (put (view :errors) id nil)
       (when (staged? store id)
         (set live true)
         (def [_ stage] (stage/moved (:load store :presentations)
                                     (:load store :stage)
                                     [:goto id ((:load store :stage) :slide)]))
         (:save store stage :stage)))
     :watch (fn [&] [RefreshView Changed
                     (if live
                       (^push :presentations :errors :stage :live)
                       (^push :presentations :errors))])}
    (. "save presentation " id)))

(defn ^build-failed
  ```
  Records why the deck `id` could not be built.

  The deck built last time stays, and stays on the stage if it is there:
  a typo saved in the middle of a lecture must not take the slide off the
  wall. The error is only said, to whoever presents.
  ```
  [id err]
  (make-event
    {:update (fn [_ {:view view}]
               (put (view :errors) id err)
               (revise view))
     :watch (^push :errors)}
    (. "build failed " id)))

(defn ^remove-presentation
  "Forgets the deck `id`, and clears the stage if it was on it."
  [id]
  (var live false)
  (make-event
    {:update
     (fn [_ {:store store :view view}]
       (when (staged? store id)
         (set live true)
         (:save store nil :stage))
       (put (:load store :presentations) id nil)
       (put (view :errors) id nil))
     :watch (fn [&] [RefreshView Changed
                     (if live
                       (^push :presentations :errors :stage :live)
                       (^push :presentations :errors))])}
    (. "remove presentation " id)))

(defn ^stage/move
  ```
  Moves the stage, telling `outcome` whether it did.

  Decided here, against the decks as they are at the moment the move is
  applied, never against what the presenter last saw of them.
  ```
  [move outcome]
  (var moved false)
  (make-event
    {:update
     (fn [_ {:store store}]
       (def [status result] (stage/moved (:load store :presentations)
                                         (:load store :stage) move))
       (put outcome :status status)
       (if (= :ok status)
         (do (:save store result :stage)
           (put outcome :stage result)
           (set moved true))
         (put outcome :reason result)))
     :watch (fn [&] (if moved [RefreshView Changed (^push :stage :live)] []))}
    (. "move stage " (string/format "%q" move))))

(def- view/empty
  @{:presentations @{}
    :stage nil
    :live nil
    :errors @{}
    :sessions @{}})

(define-event PrepareView
  "Initializes view and puts it in the dyn"
  {:update
   (fn [_ state]
     (put state :view (merge @{} view/empty {:errors @{} :sessions @{}}))
     # A new view is a new lineage of revisions: whoever holds a snapshot of
     # an older one must not take this one's for a later moment of it.
     (put (state :view) :projection/epoch (aether/hex (os/cryptorand 16))))
   :watch RefreshView
   :effect (fn [_ {:view view} _]
             (setdyn :ctx ctx)
             (setdyn :view view))})

(defn- session/of
  ```
  The session of the door `owner` guards, or nil.

  Each guardian's entrance grants a session of its own, so the tree keeps
  one per guardian, and whoever asks names the guardian -- an RPC call does
  not say who is calling.
  ```
  [view owner]
  (get-in view [:sessions owner]))

(defr +:register
  ```
  RPC function that registers the `peer`, answering with the capability of
  its `owner`'s session -- the peer's own name when it gives none.
  ```
  []
  (def [peer owner] args)
  (twm-tree/register peer (session/of view (or owner peer))))

(defr +:deregister
  "RPC function that deregisters the `peer`."
  [produce-resp ok-resp]
  (def [peer] args)
  (twm-tree/deregister peer))

(defr +:session/new
  ```
  RPC function that stores a new session for the door `owner` guards. An
  empty session ends the owner's.
  ```
  []
  (def [session owner] args)
  (assert (keyword? owner) "A session needs the guardian whose door it opens")
  (produce/applied
    (twm-tree/session/new
      session
      (twm-tree/^session/save
        session
        (fn [state value]
          (revise (state :view))
          ((=> :view :sessions (>put owner value)) state))
        (^push :cap/session))
      owner)))

(defr -:cap/session
  "Returns the session capability of the door `owner` guards."
  []
  (def [owner] args)
  (twm-tree/session/cap (session/of view owner)))

(defr -:snapshot
  ```
  Returns one coherent, revisioned projection of the collections asked for.
  Nothing here yields, so every value and the revision describe one state.
  ```
  []
  (def [colls owner] args)
  (assert (and (indexed? colls)
               (all |(index-of $ collections/projected) colls))
          "Invalid snapshot collections")
  {:epoch (view :projection/epoch)
   :revision (get view :projection/revision 0)
   :values (tabseq [coll :in colls]
             coll (if (= coll :cap/session)
                    (twm-tree/session/cap (session/of view owner))
                    (get view coll)))})

(defr +:save-presentation
  "RPC function that keeps the deck `id`, answering once it is kept."
  [applied-resp]
  (def [id deck] args)
  (assert (deck/id? id) "Invalid presentation id")
  (assert (deck? deck) (. "The presentation " id " is not a deck"))
  [(^save-presentation id deck)])

(defr +:build-failed
  "RPC function that records why the deck `id` could not be built."
  [applied-resp]
  (def [id err] args)
  (assert (deck/id? id) "Invalid presentation id")
  (assert (build-error? err) "Invalid build error")
  [(^build-failed id err)])

(defr +:remove-presentation
  "RPC function that forgets the deck `id`."
  [applied-resp]
  (def [id] args)
  (assert (deck/id? id) "Invalid presentation id")
  [(^remove-presentation id)])

(defr +:stage/move
  ```
  RPC function that moves the stage by `move`, answering with
  `{:status :ok :stage stage}` or `{:status :refused :reason reason}`.
  ```
  []
  (def move args)
  (if (move? move)
    (let [outcome @{}]
      (produce/applied [(^stage/move (tuple ;move) outcome)])
      (freeze outcome))
    {:status :refused :reason "Unknown move."}))

(def rpc-funcs
  "RPC functions for the tree"
  (merge-into
    @{:snapshot -:snapshot
      :register +:register
      :deregister +:deregister
      :session/new +:session/new
      :cap/session -:cap/session
      :save-presentation +:save-presentation
      :build-failed +:build-failed
      :remove-presentation +:remove-presentation
      :stage/move +:stage/move
      :stop twm-tree/stop
      :ping (fn [&] :pong)}
    (tabseq [coll :in [:presentations :errors :stage :live]]
      coll (fn [&] (define :view) (get view coll)))))

(def initial-state
  "Navigation to initial state in config"
  ((>update :rpc (update-rpc rpc-funcs))
    compile-config))

(twm-tree/main initial-state PrepareStore SeedStore PrepareView)
