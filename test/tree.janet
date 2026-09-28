(def conf-file "test/conf.tree.test.jdn")
(os/setenv "CONF" conf-file)
(use spork/test /environment /schema gp/net/rpc)
(def conf (parse (slurp conf-file)))
(def {:rpc rpc-url :psk psk} conf)

(import /tree)

(start-suite :docs)
(assert-docs "/tree")
(end-suite)

(def three @{:title "Three" :slides @[[:section [:h1 "One"]]
                                      [:section [:h1 "Two"]]
                                      [:section [:h1 "Three"]]]})
(def one @{:title "One" :slides @[[:section [:h1 "Only"]]]})

(start-suite :stage)
(def decks {"three" three "one" one})
(defn moved [stage & move] (tree/stage/moved decks stage move))
(def at-two {:presentation "three" :slide 2})
(assert (deep= [:ok {:presentation "three" :slide 0}] (moved nil :start "three"))
        "Starting a deck stands on its first slide")
(assert (deep= [:ok {:presentation "three" :slide 1}]
               (moved {:presentation "three" :slide 0} :next))
        "Next moves one on")
(assert (deep= [:ok at-two] (moved at-two :next))
        "Next on the last slide stays there")
(assert (deep= [:ok {:presentation "three" :slide 0}]
               (moved {:presentation "three" :slide 0} :previous))
        "Previous on the first slide stays there")
(assert (deep= [:ok at-two] (moved nil :goto "three" 9)) "Going too far lands on the last")
(assert (deep= [:ok nil] (moved at-two :stop)) "Stopping clears the stage")
(assert (= :refused (first (moved nil :next))) "Nothing to move when nothing is presented")
(assert (= :refused (first (moved nil :start "four"))) "An unknown deck cannot be started")
(end-suite)

(start-suite :live)
(let [live (tree/live/of {"three" three} {:presentation "three" :slide 1})]
  (assert (deep= [:section [:h1 "Two"]] (live :content)) "The live slide is the staged one")
  (assert (= 3 (live :count)) "and says how many there are")
  (assert (= "Three" (live :title)) "and whose they are")
  (assert (nil? (live :slides)) "A watcher is never given the rest of the deck"))
(let [parted @{:title "Course"
               :sections @[@{:title "Intro" :date "2024-02-26" :first 0 :count 2}
                           @{:title "Tools" :date "2024-02-27" :first 2 :count 1}]
               :slides (three :slides)}
      live (tree/live/of {"course" parted} {:presentation "course" :slide 2})]
  (assert (= ["Course" "Tools" "2024-02-27"] [(live :title) (live :section) (live :date)])
          "The live slide says which section it is in, and when that was"))
(assert (nil? (tree/live/of {"three" three} nil)) "Nothing is live on an empty stage")
(assert (nil? (tree/live/of {} {:presentation "gone" :slide 0}))
        "Nor on a stage whose deck is gone")
(end-suite)

(ev/sleep 0.01) # Settle the server
(setdyn :ctx ctx)

(start-suite :rpc)
(let [t (client ;(server/host-port rpc-url) "test" psk)]
  (defn move [& m] (:stage/move t ;m))
  (assert (= :ok (:save-presentation t "three" three)) "A deck is kept")
  (assert (= "Three" (get-in (:presentations t) ["three" :title])) "and can be read back")
  (assert-not (first (protect (:save-presentation t "bad" @{:title "No slides"})))
              "A deck without slides is refused")
  (assert-not (first (protect (:save-presentation t "../etc" one)))
              "An id naming another place is refused")
  (def first-revision ((:snapshot t [:stage]) :revision))

  (assert (= :ok (:build-failed t "three" {:file "three.md" :line 4 :message "Oops"}))
          "A failed build is recorded")
  (assert (= 4 (get-in (:errors t) ["three" :line])) "with its line")
  (assert (:presentations t) "The deck built before stays")
  (:save-presentation t "three" three)
  (assert (nil? (get (:errors t) "three")) "A good build forgets the error")

  (let [{:status status :stage stage} (move :start "three")]
    (assert (= :ok status) "The lecture starts")
    (assert (deep= {:presentation "three" :slide 0} stage) "on the first slide"))
  (assert (deep= [:section [:h1 "One"]] ((:live t) :content)) "The watcher's shadow follows")
  (move :next) (move :next) (move :next)
  (assert (= 2 ((:stage t) :slide)) "A clicker pressed too often stays on the last slide")
  (assert (= :refused ((move :start "nope") :status)) "An unknown deck is refused")
  (assert (= :refused ((move :jump) :status)) "So is an unknown move")

  (:save-presentation t "three" one)
  (assert (= 0 ((:stage t) :slide))
          "A deck rebuilt shorter under the stage keeps it on a slide that exists")
  (assert (deep= [:section [:h1 "Only"]] ((:live t) :content)) "and shows the new slide")

  (let [snap (:snapshot t [:stage :live])]
    (assert (string? (snap :epoch)) "A snapshot names the tree it saw")
    (assert (> (snap :revision) first-revision) "and moves on with every change")
    (assert (= "three" (get-in snap [:values :stage :presentation]))
            "and carries what was asked"))
  (assert-not (first (protect (:snapshot t [:sessions]))) "Sessions are not projected")

  (:remove-presentation t "three")
  (assert (false? (:stage t)) "Removing the staged deck clears the stage")
  (assert (false? (:live t)) "and the watchers see nothing, said as false")

  (defn cookie [session] @{:headers @{"Cookie" @{"session" session}}})
  (assert (= :applied (get (:session/new t "abcd" :presenter/sentry) :status))
          "A session is applied before it is acknowledged")
  (assert ((:cap/session t :presenter/sentry) (cookie "abcd"))
          "The presenter's door opens to it")
  (assert-not ((:cap/session t :presenter/sentry) (cookie "wxyz"))
              "and to no other")
  (assert-not ((:cap/session t :watcher) (cookie "abcd"))
              "Nobody granted the watcher a session")
  (let [cap (:register t :presenter :presenter/sentry)]
    (assert (cap (cookie "abcd"))
            "Registering answers with the session of the peer's door"))
  # The goodbye every departing peer says. Without it the tree goes on
  # dialling an address nobody answers, and on Windows a refused connect
  # holds the whole event loop for two seconds each time.
  (assert (= :ok (:deregister t :presenter)) "A peer says goodbye")
  (let [s (os/clock)]
    (:stage t)
    (assert (< (- (os/clock) s) 0.5) "and the tree stops dialling it"))
  (:session/new t "" :presenter/sentry)
  (assert-not ((:cap/session t :presenter/sentry) (cookie ""))
              "An ended session opens nothing"))
(end-suite)
