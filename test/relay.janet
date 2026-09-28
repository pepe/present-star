(def tree-conf (parse (slurp "test/conf.tree.test.jdn")))
(os/setenv "CONF" "test/conf.relay.test.jdn")
(use spork/test /environment /schema gp/net/rpc)
(import /relay)

(start-suite :docs)
(assert-docs "/relay")
(end-suite)

(setdyn :ctx ctx)
(def tree (client ;(server/host-port (tree-conf :rpc)) :test (tree-conf :psk)))
(:save-presentation tree "intro"
                    @{:title "The Intro"
                      :slides @[[:section [:h1 "One"]]
                                [:section [:h2 "Two"]]
                                [:section [:h2 "Secret third"]]]})

(ev/go relay/main)
(ev/sleep 1) # Settle the servers and the first projection

(def relay-key (key/bin "af48aff4437b39038ce55db9237739f47e6b050b954ae09bea7a2d6628fad926"))
(def elsewhere
  (identity/keypair {:public "091db711ee01cd6c96e40c075a0b0311f948a34e947dbd2d2d52aaa6b3cf7002"
                     :secret "2a07bc83c663dba6ea01c61019f2340e5da7a28760b7fdb89d0c3c6b859d7e42"}))
(def stranger
  (identity/keypair {:public "04df359178d5c1d727dc654b7465eac282dc5f5085309f302d9b8ee52a96bc40"
                     :secret "b92940249c567216e041f0b8859a03181e625e185bdd3f6f5a29dae64566dde0"}))
(defn follower [keypair &opt server-key]
  (client "localhost" 5552 "elsewhere" relay/psk
          :keypair keypair :server-key (or server-key relay-key)))

(start-suite :membrane)
(def f (follower elsewhere))
(put f :timeout 30)
(assert (function? (f :live/after)) "A follower may ask after the live slide")
(assert (nil? (f :refresh)) "and nothing the mycelium may")
(def answers @[])
(defn ask
  "Asks after `mark` in a fiber of its own, answering a channel the answer comes on."
  [mark]
  (def ch (ev/chan 1))
  (ev/go (fn []
           (def answer (:live/after f mark))
           (array/push answers answer)
           (ev/give ch answer)))
  ch)
(defn answered [ch] (ev/with-deadline 5 (ev/take ch)))

(def {:mark nothing :live none} (answered (ask nil)))
(assert (false? none) "A follower is told at once that nothing is on")
(def waiting (ask nothing))
(ev/sleep 0.3)
(assert (zero? (ev/count waiting)) "and asking again waits for the stage to move")
(:stage/move tree :stage "intro")
(def {:mark staged :live title} (answered waiting))
(assert (deep= {:presentation "intro" :title "The Intro"} title)
        "A deck staged reaches the follower as its title alone")
(def waiting (ask staged))
(:stage/move tree :present)
(def {:mark one :live live} (answered waiting))
(assert (deep= [:section [:h1 "One"]] (live :content)) "and presented, slide by slide")
(def waiting (ask one))
(:stage/move tree :next)
(assert (deep= [:section [:h2 "Two"]] ((get (answered waiting) :live) :content))
        "every one of them")
(assert-not (string/find "Secret third" (string/format "%j" answers))
            "A slide not yet shown is nowhere in what the relay said")
(:stage/move tree :close)

(assert-error "A thicket whose key the relay was not given is refused" (follower stranger))
(assert-error "and a relay that is not the one expected is left"
              (follower elsewhere (stranger :public-key)))
(end-suite)
(os/exit 0)
