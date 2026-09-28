(def tree-conf (parse (slurp "test/conf.tree.test.jdn")))
(os/setenv "CONF" "test/conf.presenter.test.jdn")
(use spork/test /environment /schema spork/http gp/net/rpc)
(import /presenter)
(import /test/support/sse)

(start-suite :docs)
(assert-docs "/presenter")
(end-suite)

(start-suite :intents)
(assert (deep= [:next] (presenter/move/of {:move "next"})) "Next")
(assert (deep= [:start "intro"] (presenter/move/of {:move "start" :deck "intro"}))
        "Start names its deck")
(assert (deep= [:goto "intro" 2] (presenter/move/of {:move "goto" :deck "intro" :slide 2}))
        "Go to names its deck and slide")
(assert (nil? (presenter/move/of {:move "jump"})) "Anything else is no move")
(assert (deep= @["b" "a" "c"]
               (presenter/deck/order @{"a" {:date "2026-03-02"}
                                       "b" {:date "2026-02-23"}
                                       "c" {:date "2026-03-02"}}))
        "Decks run in the order of their dates, then of their names")
(end-suite)

(setdyn :ctx ctx)
(def tree (client ;(server/host-port (tree-conf :rpc)) :test (tree-conf :psk)))
(:session/new tree "abcd" :presenter/sentry)
(:save-presentation tree "intro"
                    @{:title "The Intro" :date "2026-02-23"
                      :slides @[[:section [:h1 "One"]]
                                [:section [:h2 "Two"]]]})
(:build-failed tree "draft" {:file "draft.md" :line 3
                             :message "Expected `key: value` in the frontmatter"})

(def {:http http :psk psk} compile-config)
(def rpc ((parse (slurp "test/conf.presenter.test.jdn")) :rpc))
(defn url [path] (string "http://" http path))
(def cookie {"Cookie" "session=abcd"})
(defn go [body &opt headers]
  (request "POST" (url "/go")
           :headers (merge {"Content-Type" "application/json"} (or headers cookie))
           :body body))
(defn eventually
  "Waits up to two seconds for `f` to hold, answering what it answered."
  [f]
  (var res nil)
  (var n 0)
  (while (and (not (set res (f))) (< n 40)) (ev/sleep 0.05) (++ n))
  res)

(ev/go presenter/main)
(ev/sleep 1) # Settle the server and the first projection

(start-suite :http)
(let [resp (request "GET" (url "/"))]
  (assert (= 401 (resp :status)) "Nobody without the session presents")
  (assert ((??? {:body (?find "Sign in again")}) resp) "and is told how to get in"))
(let [resp (request "GET" (url "/") :headers cookie)]
  (assert ((success-has? `Presenter` `Log out` `Nothing is on the stage` `The Intro`
                         `intro.md · 2 slides · 2026-02-23`
                         `draft.md:3` `function go(`)
            resp)
          "The lecturer sees the decks, and the one that did not build"))

(def live (sse/open http "/content" "abcd"))
(assert (sse/until live 0 [`id="podium"` `Nothing is on the stage`])
        "The podium's stream starts with what is on now")
(let [m (sse/mark live)]
  (assert (= 204 ((go `{"move":"start","deck":"intro"}`) :status)) "Starting is accepted")
  (assert (sse/until live m [`<h1>One</h1>` `1 / 2` `Next` `<h2>Two</h2>`
                             `Students follow at` `http://localhost:8881`])
          "and the podium shows the slide, the next one, and where students follow"))
(assert (deep= {:presentation "intro" :slide 0} (:stage tree)) "The tree decided it")
(let [m (sse/mark live)]
  (go `{"move":"next"}`)
  (assert (sse/until live m [`2 / 2` `This is the last slide.`]) "Next moves on"))
(assert (= 401 ((go `{"move":"previous"}` {}) :status)) "A move without the session is refused")
(assert (= 400 ((go `{"move":"jump"}`) :status)) "An unknown move is refused")
(ev/sleep 0.2)
(assert (= 1 ((:stage tree) :slide)) "and neither moved the stage")

(let [m (sse/mark live)]
  (:build-failed tree "intro" {:file "intro.md" :line 7 :message "This code block is never closed."})
  (assert (sse/until live m [`2 / 2` `intro.md:7` `never closed`])
          "A broken save of the staged deck is said, and the slide stays"))

(let [p (client ;(server/host-port rpc) :test psk)
      [what at] (:ping p)]
  (assert (= :last-active what) "The presenter reports its last use")
  (assert (>= at (- (os/time) 1)) "and while a deck is on the stage, that is now")
  (:close p))

(let [m (sse/mark live)]
  (:save-presentation tree "CULS-Backend"
                      @{:title "CULS Backend" :date "2024-02-26"
                        :sections @[@{:title "The Intro" :first 0 :count 2 :date "2024-02-26"}
                                    @{:title "Tools" :first 2 :count 1 :date "2024-02-27"}]
                        :slides @[[:section [:h1 "Hi"]] [:section [:h2 "Who"]]
                                  [:section [:h2 "Tools"]]]})
  (assert (sse/until live m [`CULS Backend` `3 slides in 2 sections`
                             `go(&quot;goto&quot;,&quot;CULS-Backend&quot;,2)` `Tools`])
          "A deck in sections offers each of them to start from"))
(let [m (sse/mark live)]
  (go `{"move":"goto","deck":"CULS-Backend","slide":2}`)
  (assert (sse/until live m [`<h2>Tools</h2>` `3 / 3` `Tools` `1 of 1`
                             `CULS Backend · Tools · 2024-02-27`])
          "and starting from one says which section is on"))

(let [m (sse/mark live)]
  (go `{"move":"stop"}`)
  (assert (sse/until live m [`Nothing is on the stage`]) "Stopping clears the podium"))
(sse/close live)
(end-suite)
(os/exit 0)
