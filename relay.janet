(use /environment /schema)
(import twm/symbiont :as symbiont)
(import twm/subscription)

(setdyn *rpc-defines* [:view])

(def followed
  ```
  What the relay follows of the tree: the live slide, and nothing else.

  The relay is the watcher's other face, turned to thickets rather than
  browsers. It can hand a follower no more than the students' page shows,
  because it never holds more.
  ```
  [:live])

(defn live/mark
  "Where the relay's view of the live slide stands: the tree it saw, and the revision."
  [view]
  [(view :projection/epoch) (get-in view [:projection/revisions :live])])

(defr -:live/after
  ```
  RPC function answering `{:mark mark :live live}` -- the live slide, and
  the mark to ask after next -- once the relay's view of it has moved on
  from `seen`, or after `relay/wait` seconds as it stands.

  The follower asks again at once. It is the one who dials and waits, so a
  thicket nobody can dial -- a laptop behind a router -- follows as well
  as one on a server.
  ```
  []
  (def [seen] args)
  (def sub (subscription/open view followed))
  (defer (subscription/close sub)
    (protect
      (ev/with-deadline relay/wait
        (while (= seen (live/mark view))
          (subscription/take sub))))
    {:mark (live/mark view) :live (view :live)}))

(def membrane/funcs
  "RPC functions of the relay's membrane: all a follower may ask."
  @{:live/after -:live/after})

(define-watch MembraneRPC
  ```
  Opens the relay to the thickets whose public keys it was given, as
  `:followers`, and to no others. It is known to them by its own
  `:identity`.
  ```
  [_ {:membrane/rpc {:url url :functions functions} :identity identity
      :followers followers :name name :debug deb} _]
  (assert (identity? identity) "The relay needs an :identity to be known by")
  (assert (all key/hex? (values (or followers {}))) "A follower's key is not a key")
  (^rpc url
        (merge functions {:keypair (identity/keypair identity)
                          :allowed (map key/bin (values (or followers {})))})
        relay/psk name deb))

(define-event PrepareView
  "Initializes the view and puts it in the dyn"
  {:update
   (fn [_ state]
     (put state :view @{:name (state :name)}))
   :effect (fn [_ {:view view} _]
             (setdyn :ctx ctx)
             (setdyn :view view))})

(def rpc-funcs
  "RPC functions"
  @{:refresh (refresh/following followed)})

(def initial-state
  "Initial state"
  ((=> (>update :rpc (update-rpc rpc-funcs))
       (>update :membrane/rpc (update-rpc membrane/funcs)))
    compile-config))

(symbiont/main initial-state (^start PrepareView followed) MembraneRPC)
