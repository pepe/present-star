(os/setenv "CONF" "test/conf.test.jdn")
(use spork/test /schema /environment)
(import /bin/test-confs)

(start-suite :docs)
(assert-docs "/environment")
(assert-docs "/schema")
(end-suite)

(start-suite :config)
(each sym test-confs/symbionts
  (assert (deep= ((=>symbiont/initial-state sym) compile-config)
                 (parse (slurp (test-confs/fixture sym))))
          (. sym " config navigation; run bin/test-confs.janet after changing the config")))

# The sentry is a peer of the demiurge like any other. When the presenter
# stands down, the demiurge hands the door back by dialling the sentry --
# an asking wrapped in a protect, so a sentry it cannot dial fails silently
# and leaves the door dead behind a lecturer who has just signed out.
(let [demiurge ((=>symbiont/initial-state :demiurge) compile-config)]
  (assert (demiurge :presenter/sentry) "The demiurge can dial the sentry")
  (assert (false? (demiurge :builder)) "and its own :builder is still its own"))
(assert (= :presenter/sentry ((=> :symbionts :presenter :guarded-by) compile-config))
        "The presenter is guarded by the sentry")

(let [example (parse (slurp "conf.example.jdn"))]
  (assert (config/base? example) "The show.pan.earth example has twm's shape")
  (assert (= example (config/guardians! example)) "and is wired to hand its door back"))

(defn refused [config]
  (match (protect (config/guardians! config))
    [false err] err
    [true _] "accepted"))
(defn with-symbiont [name block]
  (def config (thaw (parse (slurp "test/conf.test.jdn"))))
  (put-in config [:symbionts name] block)
  (put-in config [:mycelium :nodes name] {:rpc "localhost:5599" :peers [:tree]})
  config)
(assert (string/find "builder is named like a setting"
                     (refused (with-symbiont :builder {:entry "decker.janet"})))
        "A symbiont called builder would answer for the demiurge's :builder")
(let [config (thaw (parse (slurp "test/conf.test.jdn")))]
  (put-in config [:mycelium :nodes :tree :peers] [:presenter :watcher])
  (assert (string/find "presenter/sentry is missing from the tree's :peers"
                       (refused config))
          "A sentry the tree cannot push the session to is refused"))
(let [config (thaw (parse (slurp "test/conf.test.jdn")))]
  (put-in config [:symbionts :demiurge :autostart] [:tree :decker :presenter :watcher])
  (assert (string/find "only its guardian may raise it" (refused config))
          "The presenter is raised by its sentry, never at start"))
(end-suite)

(start-suite :slides)
(def deck {:title "T" :author "A" :date "D" :slides [[:section [:h1 "1"]] [:section [:h1 "2"]]]})
(assert (deep= [:section [:h1 "2"]] (slide/at deck 1)) "A slide is found by its index")
(assert (nil? (slide/at deck 2)) "There is nothing after the last")
(assert (nil? (slide/at deck -1)) "nor before the first")
(assert (deep= [:div {:class "slide"} [:section]] (<slide/> nil)) "An absent slide is an empty frame")
(assert (deep= [:div {:class "slide preview"} [:section [:h1 "1"]]]
               (<slide/> (slide/at deck 0) "preview"))
        "A slide may be framed as a preview")
(assert (= "T · A · D" (last (<deck/line/> deck))) "A deck says what, who and when")
(assert (= "T" (last (<deck/line/> {:title "T"}))) "and leaves out what it does not know")
(assert (= "Course · Tools · D" (last (<deck/line/> {:title "Course" :section "Tools" :date "D"})))
        "A deck in parts says which part")
(assert (= "Present Star" (last (<deck/line/> {:title "Present Star" :section "Present star"})))
        "but not a part called what the deck is")
(let [parted {:sections [{:title "A" :first 0 :count 2} {:title "B" :first 2 :count 1}]}]
  (assert (= "B" ((section/at parted 2) :title)) "A slide belongs to the section it falls in")
  (assert (nil? (section/at parted 3)) "and past the last one, to none"))
(end-suite)
