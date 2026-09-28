(use /environment /schema)
(import twm/tree :as twm-tree)
(import twm/delivery)
(import /notes)

(setdyn *rpc-defines* [:view])

(def collections/stored
  "What the tree keeps in its image: the decks, where the stage is, and the notes."
  [:presentations :stage :notes])

(def collections/projected
  "Collections a peer may ask the tree to project in one snapshot."
  [:cap/session :presentations :errors :stage :live :notes])

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
  the deck beyond it. Of a deck staged but not presented, its title alone.

  A watcher is a cosymbiont. It follows the lecture and needs no more than
  what the lecturer has shown; holding the rest of the deck would put the
  next slides a view-source away from every student.
  ```
  [presentations stage]
  (when-let [{:presentation id :slide n :presenting shown} stage
             deck (get presentations id)]
    (if shown
      (let [section (or (section/at deck n) {})]
        {:presentation id
         :title (deck :title)
         :section (section :title)
         :author (get section :author (deck :author))
         :date (get section :date (deck :date))
         :slide n
         :count (length (deck :slides))
         :content (get-in deck [:slides n])})
      {:presentation id :title (deck :title)})))

(defn stage/moved
  ```
  Where `move` takes `stage` among `presentations`, as `[:ok stage]`, or
  `[:refused reason]`.

  A deck comes onto the stage unseen: the students are shown its title,
  while the lecturer pages through it and writes notes. `:present` shows
  them its slides, from the one the lecturer is on, and `:stop` hides them
  again with the deck still staged. `:close` takes it off the stage. Going
  to another deck stages it unseen too.

  Slides are counted from zero and a move never leaves the deck: the next
  slide after the last is the last. Going past the end is what a clicker
  does when a lecturer presses once too often, and it is not an error.
  ```
  [presentations stage move]
  (defn last-of [id] (max 0 (dec (length (get-in presentations [id :slides] [])))))
  (defn at [id n shown]
    {:presentation id :slide (min (max 0 n) (last-of id)) :presenting shown})
  (def staged (get stage :presentation))
  (def shown (truthy? (get stage :presenting)))
  (defn gone [id] [:refused (. "There is no presentation " id ".")])
  (match [(length move) ;move]
    [2 :stage id] (if (presentations id) [:ok (at id 0 false)] (gone id))
    [3 :goto id n] (if (presentations id)
                     [:ok (at id n (and shown (= id staged)))]
                     (gone id))
    [1 :close] [:ok nil]
    (if stage
      (match move
        [:next] [:ok (at staged (inc (stage :slide)) shown)]
        [:previous] [:ok (at staged (dec (stage :slide)) shown)]
        [:present] [:ok (at staged (stage :slide) true)]
        [:stop] [:ok (at staged (stage :slide) false)]
        [:refused "Unknown move."])
      [:refused "Nothing is staged."])))

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
  (put view :notes (notes/projected (or (:load store :notes) @{})))
  (revise view))

(define-update EnsureNotes
  ```
  Gives the store a place for notes. A store kept from before there were
  any holds only the decks and the stage, and the store never makes a
  place by itself.
  ```
  [_ {:store store}]
  (unless (:load store :notes) (:save store @{} :notes)))

(define-update KeepPresenting
  ```
  Keeps a stage stored before decks were staged as it was: presented.
  Such a stage does not say `:presenting`, and whatever stood on it was on
  the wall -- a release in the middle of a lecture must leave it there.
  ```
  [_ {:store store}]
  (when-let [stage (:load store :stage)]
    (if (nil? (get stage :presenting))
      (:save store (merge stage {:presenting true}) :stage))))

(defn- notes/held
  "The notes on the deck `id`, made empty in the `store` when it has none."
  [store id]
  (or (:load store :notes id)
      (let [held @{:slides @{} :orphans @[]}]
        (:save store held :notes id)
        held)))

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
  nothing. Its notes go with their slides to wherever the rebuild put
  them, and a note whose slide is gone is kept as an orphan.
  ```
  [id deck]
  (def topics @[:presentations :errors])
  (make-event
    {:update
     (fn [_ {:store store :view view}]
       (def old (:load store :presentations id))
       (:save store deck :presentations id)
       (put (view :errors) id nil)
       (when-let [held (:load store :notes id)]
         (def [placed orphans]
           (notes/reanchored (held :slides) (get old :slides) (deck :slides)))
         (put held :slides placed)
         (each orphan orphans
           (array/push (held :orphans) (put orphan :id (aether/hex (os/cryptorand 6)))))
         (array/push topics :notes))
       (when (staged? store id)
         (array/push topics :stage :live)
         (def [_ stage] (stage/moved (:load store :presentations)
                                     (:load store :stage)
                                     [:goto id ((:load store :stage) :slide)]))
         (:save store stage :stage)))
     :watch (fn [&] [RefreshView Changed (^push ;topics)])}
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
  ```
  Forgets the deck `id`, and clears the stage if it was on it. Its notes
  stay: a file gone for a moment, in a checkout, comes back to them.
  ```
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
  applied, never against what the presenter last saw of them. The watchers
  are told only when what they see changed: a lecturer paging through a
  staged deck moves nothing on the wall.
  ```
  [move outcome]
  (def topics @[])
  (make-event
    {:update
     (fn [_ {:store store}]
       (def presentations (:load store :presentations))
       (def before (:load store :stage))
       (def [status result] (stage/moved presentations before move))
       (put outcome :status status)
       (if (= :ok status)
         (do (:save store result :stage)
           (put outcome :stage result)
           (array/push topics :stage)
           (unless (deep= (live/of presentations before) (live/of presentations result))
             (array/push topics :live)))
         (put outcome :reason result)))
     :watch (fn [&] (if (empty? topics) [] [RefreshView Changed (^push ;topics)]))}
    (. "move stage " (string/format "%q" move))))

(defn ^notes/change
  ```
  Changes the notes as `change` says, telling `outcome` whether it did.
  Only the presenter follows the notes, so only the presenter is told.
  ```
  [change outcome]
  (var changed false)
  (make-event
    {:update
     (fn [_ {:store store}]
       (def id (change 1))
       (def refusal
         (if-let [deck (:load store :presentations id)]
           (notes/changed (notes/held store id) deck change)
           (. "There is no presentation " id ".")))
       (if refusal
         (merge-into outcome {:status :refused :reason refusal})
         (do (put outcome :status :ok)
           (set changed true))))
     :watch (fn [&] (if changed [RefreshView Changed (^push :notes)] []))}
    (. "change notes " (change 0) " " (change 1))))

(def- view/empty
  @{:presentations @{}
    :stage nil
    :live nil
    :notes @{}
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

(defr +:notes/change
  ```
  RPC function that changes the notes by `change` -- `[:write id n text]`,
  `[:attach id orphan n]` or `[:drop id orphan]` -- answering with
  `{:status :ok}` or `{:status :refused :reason reason}`.
  ```
  []
  (def change args)
  (if (note/change? change)
    (let [outcome @{}]
      (produce/applied [(^notes/change (tuple ;change) outcome)])
      (freeze outcome))
    {:status :refused :reason "Unknown change."}))

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
      :notes/change +:notes/change
      :stop twm-tree/stop
      :ping (fn [&] :pong)}
    (tabseq [coll :in [:presentations :errors :stage :live :notes]]
      coll (fn [&] (define :view) (get view coll)))))

(def initial-state
  "Navigation to initial state in config"
  ((>update :rpc (update-rpc rpc-funcs))
    compile-config))

(twm-tree/main initial-state
               PrepareStore SeedStore EnsureNotes KeepPresenting PrepareView)
