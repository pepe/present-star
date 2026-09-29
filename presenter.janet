(use /environment /schema)
(import twm/symbiont :as symbiont)
(import twm/sentry
        :only [session/check-with /logout StandDown] :prefix "")

(setdyn *handler-defines* [:view])

(def followed
  "What the presenter follows of the tree."
  [:presentations :errors :stage :notes :attending :cap/session])

(def stage/stand-down
  ```
  The notice telling a live `/content` stream its presenter is going.

  A logout is asked for and answered with its own transition. A stop the
  demiurge orders -- the idle timeout -- is asked for by nobody, and the
  stream would simply die under a page still showing a place that has
  gone. This is how that leaving reaches the page.
  ```
  :stage/stand-down)

(defn deck/order
  ```
  The ids of `decks`, the one saved last first: the deck being worked on is
  the one about to be presented. Decks saved at the same moment -- a fresh
  checkout saves them all at once -- follow the order of their names, and a
  deck with no time of saving comes last.
  ```
  [decks]
  (sorted-by |[(- (get-in decks [$ :modified] 0)) $] (keys decks)))

(defn- <go/>
  "A button carrying one intent to the stage."
  [text & intent]
  [:button {:onclick (string "go(" (string/join (map json/encode intent) ",") ")")}
   text])

(defn- <failure/>
  [{:file file :line line :message message}]
  [:p {:class "error"}
   [:strong file (if line (. ":" line))] " " message])

(defn- <note/>
  ```
  The lecturer's note on slide `n` of the deck `id`, written where it is
  read, and saved when the lecturer leaves it.

  Datastar sets a textarea to what every push says, which would take back
  whatever was typed since the last save. So the note is never morphed,
  and is named after its deck, slide and text instead: a push that changes
  any of them brings a new one in its place.
  ```
  [id n text]
  [:textarea {:id (string "note-" (hash (string/join [id (string n) (or text "")] "\n")))
              :class "note"
              :data-ignore-morph true
              :rows 5
              :maxlength 4000
              :placeholder "Notes on this slide, for you alone"
              :onchange (string "note(" (json/encode {:deck id :slide n}) ", this.value)")}
   (or text "")])

(defn- <orphans/>
  "The notes whose slide left the deck `id`, to put on slide `n`, or to forget."
  [id n orphans]
  (unless (empty? orphans)
    [:section {:class "orphans"}
     [:h3 "Notes whose slide is gone"]
     (seq [{:id oid :text text :anchor anchor :was was} :in orphans]
       [:div {:class "orphan"}
        (<slide/> anchor "preview")
        [:p {:class "muted"} "Was on slide " (inc was)]
        [:p {:class "note-text"} text]
        [:div {:class "controls"}
         [:button {:onclick (string "note(" (json/encode {:deck id :orphan oid :slide n}) ")")}
          "Put on this slide"]
         [:button {:onclick (string "note(" (json/encode {:deck id :orphan oid}) ")")}
          "Forget"]]])]))

(defn- <source/>
  "Where slide `n` of a recorded `deck` stood in the lecturer's own."
  [deck n]
  (def {:at at :count total} (deck :recorded))
  (. "slide " (inc (at n)) " of " total))

(defn- <tabs/>
  ```
  The presenter's two tabs: the stage, and the lectures attended elsewhere.
  Each is an address of its own, so both may be open at once, side by
  side. Wherever it is seen from, the attending tab says how many are on.
  ```
  [current attending]
  [:nav {:class "tabs"}
   [:a {:href "/" :class (if (= current :stage) "active")} "Stage"]
   [:a {:href "/attending" :class (if (= current :attending) "active")}
    "Attending"
    (unless (empty? attending) [:span {:class "badge"} (length attending)])]])

(defn <attending/>
  ```
  The lectures followed from other thickets, each on the slide it shows
  now, as recorded, with the lecturer's own note on it; nil for none.
  ```
  [attending decks notes]
  (unless (empty? attending)
    [:section {:class "attending"}
     (seq [from :in (sorted (keys attending))
           :let [{:title title :presentation id :slide n} (attending from)
                 deck (get decks id)]]
       [:div {:class "attended"}
        [:p [:strong title] [:span {:class "muted"} " · from " from]]
        (if (and deck n (slide/at deck n))
          [:div {:class "on-stage"}
           (<slide/> (slide/at deck n))
           [:aside {:class "side"}
            [:p {:class "part"} (<source/> deck n)]
            [:h3 "Notes"]
            (<note/> id n (get-in notes [id :slides n]))]]
          [:p {:class "muted"} "Staged, not presented yet."])])]))

(defn <on-stage/>
  ```
  The staged slide, what comes after it, its note, and the controls. The
  students see the slide only once it is presented; until then, only the
  deck's title.
  ```
  [id deck stage err watcher held]
  (def n (stage :slide))
  (def shown (stage :presenting))
  (def total (length (deck :slides)))
  (def part (or (section/at deck n) {}))
  (def parted (> (length (get deck :sections [])) 1))
  [:div {:class "on-stage"}
   (<slide/> (slide/at deck n))
   [:aside {:class "side"}
    (if shown
      [:p {:class "state presenting"} "Presenting · the students follow"]
      [:p {:class "state"} "Staged · the students see only the title"])
    [:p {:class "position"} (inc n) " / " total]
    (if (and parted (part :title))
      [:p {:class "part"} [:strong (part :title)] " · "
       (inc (- n (part :first))) " of " (part :count)])
    [:div {:class "controls"}
     (<go/> "← Previous" "previous")
     (if shown
       [:button {:class "primary" :onclick "go(\"next\")"} "Next →"]
       (<go/> "Next →" "next"))
     (if shown
       (<go/> "Stop" "stop")
       [:button {:class "primary" :onclick "go(\"present\")"} "Present"])
     (unless shown (<go/> "Close" "close"))]
    [:h3 "Notes"]
    (<note/> id n (get-in held [:slides n]))
    [:h3 "Next"]
    (if-let [upcoming (slide/at deck (inc n))]
      (<slide/> upcoming "preview")
      [:p {:class "the-end"} "This is the last slide."])
    (<deck/line/> {:title (deck :title)
                   :section (part :title)
                   :author (get part :author (deck :author))
                   :date (get part :date (deck :date))})
    (if err (<failure/> err))
    (if watcher
      [:p {:class "follow"} "Students follow at "
       [:a {:href watcher :target "_blank" :rel "noopener"} watcher]])
    (<orphans/> id n (get held :orphans []))]])

(defn <decks/>
  ```
  Every deck the tree holds, with how its last build went. While one is
  on the stage it is the only one, and the others come back once it is
  closed.
  ```
  [decks errors stage notes]
  (def staged (get stage :presentation))
  (def unbuilt (if staged [] (seq [id :keys errors :unless (decks id)] id)))
  [:section {:class "decks"}
   [:h2 (if staged "On the stage" "Decks")]
   (if (and (empty? decks) (empty? unbuilt))
     [:p {:class "muted"} "No decks yet. Save a Markdown deck into the sources."])
   [:ul
    (seq [id :in (if staged [staged] (deck/order decks))
          :let [deck (decks id)
                parts (get deck :sections [])
                noted (length (get-in notes [id :slides] {}))]
          :when deck]
      [:li (if (= id staged) {:class "staged"} {})
       (unless (= id staged) (<go/> "Stage" "stage" id))
       [:strong (deck :title)]
       [:span {:class "muted"}
        ;(if-let [{:from from :count total} (deck :recorded)]
           ["recorded from " from " · " (length (deck :slides)) " of " total " slides"]
           [id ".md · " (length (deck :slides)) " slides"])
        (if (> (length parts) 1) (. " in " (length parts) " sections"))
        (if (deck :date) (. " · " (deck :date)))
        (case noted 0 "" 1 " · 1 note" (. " · " noted " notes"))]
       (if-let [err (errors id)] (<failure/> err))
       # A deck in parts can be taken up at any of them: a course deck is
       # presented a section a lecture.
       (if (> (length parts) 1)
         [:ol {:class "parts"}
          (seq [part :in parts]
            [:li (<go/> (part :title) "goto" id (part :first))
             [:span {:class "muted"} (part :count) " slides"
              (if (part :date) (. " · " (part :date)))]])])])
    (seq [id :in (sorted unbuilt)]
      [:li [:strong id ".md"] (<failure/> (errors id))])]])

(defn <podium/>
  "Everything the presenter shows, rendered from the view."
  []
  (define :view)
  (def decks (or (view :presentations) {}))
  (def errors (or (view :errors) {}))
  (def notes (or (view :notes) {}))
  (def stage (view :stage))
  (def id (get stage :presentation))
  (def deck (get decks id))
  [:div {:id "podium"}
   (<tabs/> :stage (or (view :attending) {}))
   (if deck
     (<on-stage/> id deck stage (errors id) (view :watcher) (get notes id))
     [:section {:class "idle"}
      [:h2 "Nothing is on the stage"]
      [:p {:class "muted"}
       "Stage one of the decks below. The students see only its title "
       "until you present it."]])
   (<decks/> decks errors stage notes)])

(defn <attended/>
  "Everything the attending tab shows, rendered from the view."
  []
  (define :view)
  (def attending (or (view :attending) {}))
  [:div {:id "podium"}
   (<tabs/> :attending attending)
   (or (<attending/> attending (or (view :presentations) {}) (or (view :notes) {}))
       [:section {:class "idle"}
        [:h2 "Nothing is attended"]
        [:p {:class "muted"}
         "A lecture given from a thicket this one follows shows here while "
         "it is on. What it showed is recorded among the decks."]])])

(def- <notes/script/>
  ```
  The one place a page asks anything of the notes. `note` carries only
  intent, and the page shows the note the tree pushes back.
  ```
  [:script
   (hg/raw
     ``function note(intent, text) {
        if (text !== undefined) intent.text = text;
        fetch("/note", {method: "POST",
                        headers: {"Content-Type": "application/json"},
                        body: JSON.stringify(intent)});
      }``)])

(def- <keys/>
  ```
  The one place the stage tab asks anything of the stage.

  Keys, clickers and buttons all gather intent; `go` alone carries it, and
  it carries only intent. The page does not move itself: it shows the
  slide the tree says is on the stage, pushed back over `/content`, so the
  lecturer sees exactly what the students see. The keys are the stage
  tab's alone: on the attending tab, somebody else's lecture is on.
  ```
  [:script
   (hg/raw
     ``function go(move, deck, slide) {
        fetch("/go", {method: "POST",
                      headers: {"Content-Type": "application/json"},
                      body: JSON.stringify({move: move, deck: deck, slide: slide})});
      }
      document.addEventListener("keydown", function (e) {
        if (e.target.closest("input, textarea, select") || e.altKey || e.ctrlKey || e.metaKey) return;
        if (["ArrowRight", "PageDown", " "].includes(e.key)) { e.preventDefault(); go("next"); }
        else if (["ArrowLeft", "PageUp"].includes(e.key)) { e.preventDefault(); go("previous"); }
      });``)])

(defn <not-auth/>
  "What a request without the presenter's session is answered with."
  []
  (<page/> "Presenter"
           [:main {:id "stage"}
            [:p "Your session is not valid. " [:a {:href "/"} "Sign in again"]]]))

(defn ^activity
  "Event that marks the presenter as used at `ts`."
  [ts]
  (make-update
    (fn [_ {:view view}] (put view :last-active ts))
    "activity"))

(def session/admitted
  ```
  Admits a request with a valid session, without counting it as use.

  For the page's `/content` stream alone. The browser opens it again by
  itself whenever it is cut, and a reopening nobody asked for is not use.
  ```
  (session/check-with (<not-auth/>)))

(defn session/checker
  "Admits a request with a valid session, and counts it as use."
  [next-middleware]
  (session/admitted
    (fn counted [req]
      (produce (^activity (os/time)))
      (next-middleware req))))

(defh /index
  "The presenter's stage tab."
  [page/app session/checker]
  ["Presenter"
   @[[:div {:data-init (ds/get "/content")} (<podium/>)]
     <notes/script/>
     <keys/>]
   :logout])

(defh /attending
  "The presenter's attending tab: the lectures followed from elsewhere."
  [page/app session/checker]
  ["Attending"
   @[[:div {:data-init (ds/get "/attending/content")} (<attended/>)]
     <notes/script/>]
   :logout])

(defn- live
  ```
  A tab's one live stream, rendering `render` once, and again every time
  the tree says anything the presenter follows changed. A presenter going
  away takes the tab back to the door.
  ```
  [view render]
  (view/stream
    view [;followed stage/stand-down]
    (fn [] (ds/hg/patch (render)))
    (fn [_] (ds/hg/patch (render)))
    (fn []
      (protect
        (:write (dyn :sse-conn) (view :transition/logout))
        (:flush (dyn :sse-conn))))))

(defh /content
  "The stage tab's live stream, of the podium."
  [session/admitted]
  (live view <podium/>))

(defh /attending/content
  "The attending tab's live stream, of the lectures attended."
  [session/admitted]
  (live view <attended/>))

(defn move/of
  "The move the lecturer's `intent`, as `/go` receives it, asks for, or nil."
  [{:move m :deck deck :slide slide}]
  (case m
    "next" [:next]
    "previous" [:previous]
    "present" [:present]
    "stop" [:stop]
    "close" [:close]
    "stage" [:stage deck]
    "goto" [:goto deck slide]))

(defn ^stage/move
  ```
  Carries the lecturer's intent to the tree, which decides.

  Nothing here assumes the move happened. The tree answers every
  registered presenter and watcher with the stage it settled on, and that
  push is what the page shows.
  ```
  [move]
  (make-effect
    (fn [_ {:tree tree :name name} _]
      (match (protect (:stage/move tree ;move))
        [true {:status :refused :reason reason}]
        (eprint name " stage move " (string/format "%q" move) " refused: " reason)
        [false err]
        (eprint name " could not move the stage: " err)))
    "move stage"))

(defh /go
  "Accepts one intent for the stage, and hands it to the tree."
  [session/checker http/keywordize-body http/json->body]
  (def move (move/of (or body {})))
  (if (move? move)
    (do (produce (^stage/move move))
      (http/no-content))
    (http/bad-request)))

(defn note/of
  "The change the lecturer's `intent`, as `/note` receives it, asks of the notes, or nil."
  [{:deck deck :slide slide :text text :orphan orphan}]
  (cond
    text [:write deck slide text]
    (and orphan slide) [:attach deck orphan slide]
    orphan [:drop deck orphan]))

(defn ^notes/change
  ```
  Carries the lecturer's change of the notes to the tree, which keeps them.
  The page shows the note the tree pushes back, as it shows the stage.
  ```
  [change]
  (make-effect
    (fn [_ {:tree tree :name name} _]
      (match (protect (:notes/change tree ;change))
        [true {:status :refused :reason reason}]
        (eprint name " note change " (change 0) " refused: " reason)
        [false err]
        (eprint name " could not change the notes: " err)))
    "change notes"))

(defh /note
  "Accepts one change of the notes, and hands it to the tree."
  [session/checker http/keywordize-body http/json->body]
  (def change (note/of (or body {})))
  (if (note/change? change)
    (do (produce (^notes/change change))
      (http/no-content))
    (http/bad-request)))

(defr -:ping/active
  ```
  RPC function reporting when the presenter was last used.

  While a deck is on the stage it is in use now: a lecturer may talk over
  one slide for as long as it takes, and being stopped for it would be
  stopped mid-lecture. So it is while a lecture is attended: listening
  is use too, even with nothing written.
  ```
  []
  (define :view)
  (def busy (or (view :stage) (not (empty? (or (view :attending) {})))))
  [:last-active (if busy (os/time) (view :last-active))])

(defn ^stand-down/after-stage
  "Waits for live streams to finish their leaving, within a bound, and stands down."
  []
  (make-watch
    (fn [_ {:view view} _]
      (producer
        (protect (subscription/drain view stage/stand-down 1))
        (produce StandDown)))
    "stand down after stage responses"))

(defr +:stop/guarded
  ```
  RPC function that stops the presenter -- the demiurge's, when it has
  been idle too long. Whoever is watching the page is told first, over the
  stream they hold, and the page goes back to the door.
  ```
  [produce-resp ok-resp]
  (define :view)
  [(log (view :name) "'s RPC server stops")
   (^notify/send stage/stand-down)
   (^stand-down/after-stage)])

(define-event PrepareView
  "Initializes the view and puts it in the dyn"
  {:update
   (fn [_ state]
     (put state :view
          @{:cap/session (>base false)
            # Standing up counts as use: the idle clock starts now, not at
            # a first request that may never come.
            :last-active (os/time)
            :name (state :name)
            :watcher (state :watcher)
            # A logout hands the door back to the sentry, which answers on
            # this very address.
            :transition/logout
            (transition/leaving (state :address) (state :name))}))
   :effect (fn [_ {:view view} _]
             (setdyn :ctx ctx)
             (setdyn :view view))})

(def routes
  "HTTP routes"
  @{"/" /index
    "/content" /content
    "/attending" /attending
    "/attending/content" /attending/content
    "/go" (http/dispatch {"POST" /go})
    "/note" (http/dispatch {"POST" /note})
    "/logout" /logout})

(def rpc-funcs
  "RPC functions"
  @{:refresh (refresh/following followed)
    # Reporting last use is what lets the demiurge stop a presenter left idle.
    :ping -:ping/active
    :stop +:stop/guarded})

(def initial-state
  "Initial state"
  ((=> (>put :routes routes)
       (>update :rpc (update-rpc rpc-funcs)))
    compile-config))

(symbiont/main initial-state
               (^start PrepareView [:presentations :errors :stage :notes :attending])
               HTTP)
