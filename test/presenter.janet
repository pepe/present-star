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
(assert (deep= [:stage "intro"] (presenter/move/of {:move "stage" :deck "intro"}))
        "Staging names its deck")
(assert (deep= [:present] (presenter/move/of {:move "present"})) "Present")
(assert (deep= [:close] (presenter/move/of {:move "close"})) "Close")
(assert (deep= [:write "intro" 1 "hi"] (presenter/note/of {:deck "intro" :slide 1 :text "hi"}))
        "A note is written on its slide")
(assert (deep= [:attach "intro" "o1" 0] (presenter/note/of {:deck "intro" :orphan "o1" :slide 0}))
        "An orphan is put on a slide")
(assert (deep= [:drop "intro" "o1"] (presenter/note/of {:deck "intro" :orphan "o1"}))
        "or forgotten")
(assert (deep= [:goto "intro" 2] (presenter/move/of {:move "goto" :deck "intro" :slide 2}))
        "Go to names its deck and slide")
(assert (nil? (presenter/move/of {:move "jump"})) "Anything else is no move")
(assert (deep= @["b" "a" "c" "d"]
               (presenter/deck/order @{"a" {:modified 100 :date "2026-02-23"}
                                       "b" {:modified 300 :date "2024-01-01"}
                                       "c" {:modified 100}
                                       "d" {:date "2026-09-28"}}))
        "Decks run from the one saved last, then by name, unsaved ones last")
(end-suite)

(setdyn :ctx ctx)
(def tree (client ;(server/host-port (tree-conf :rpc)) :test (tree-conf :psk)))
(:session/new tree "abcd" :presenter/sentry)
(:save-presentation tree "intro"
                    @{:title "The Intro" :date "2026-02-23" :modified 2000000000
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
                         `draft.md:3` `function note(` `function go(`)
            resp)
          "The lecturer sees the decks, and the one that did not build"))

(defn note [body]
  (request "POST" (url "/note")
           :headers (merge {"Content-Type" "application/json"} cookie)
           :body body))

(def live (sse/open http "/content" "abcd"))
(assert (sse/until live 0 [`id="podium"` `Nothing is on the stage`])
        "The podium's stream starts with what is on now")
(let [m (sse/mark live)]
  (assert (= 204 ((go `{"move":"stage","deck":"intro"}`) :status)) "Staging is accepted")
  (def sent (sse/until live m [`<h1>One</h1>` `Staged` `1 / 2` `Present` `Close`
                               `Notes` `data-ignore-morph` `Next` `<h2>Two</h2>`
                               `Students follow at` `http://localhost:8881`
                               `On the stage` `The Intro`]))
  (assert sent "and the podium shows the slide, its note, the next one, and where students follow")
  (assert-not (string/find "draft.md" sent) "The other decks are put away meanwhile")
  (assert (string/find "Ctrl+← and Ctrl+→ move through the deck" sent)
          "The note says how to move on from it")
  (assert (string/find `data-slide="0"` sent) "and knows its slide"))
(assert (deep= {:presentation "intro" :slide 0 :presenting false} (:stage tree))
        "The tree decided it, and shows the students nothing yet")

(let [m (sse/mark live)]
  (assert (= 204 ((note `{"deck":"intro","slide":0,"text":"Say hello first"}`) :status))
          "A note is accepted")
  (assert (sse/until live m [`data-ignore-morph` `Say hello first</textarea>` `1 note`])
          "and comes back on its slide, and counted with its deck"))
(assert (= "Say hello first" (get-in (:notes tree) ["intro" :slides 0])) "The tree keeps it")
(assert (= 400 ((note `{"deck":"intro"}`) :status)) "A change that says nothing is refused")

(let [m (sse/mark live)]
  (go `{"move":"next"}`)
  (assert (sse/until live m [`2 / 2` `This is the last slide.`])
          "Next pages through the staged deck"))
(let [m (sse/mark live)]
  (go `{"move":"present"}`)
  (assert (sse/until live m [`<h2>Two</h2>` `Presenting` `2 / 2` `Stop`])
          "Presenting starts from the slide the lecturer is on"))
(assert ((:stage tree) :presenting) "and the tree says it is presented")
(assert (= 401 ((go `{"move":"previous"}` {}) :status)) "A move without the session is refused")
(assert (= 400 ((go `{"move":"jump"}`) :status)) "An unknown move is refused")
(ev/sleep 0.2)
(assert (= 1 ((:stage tree) :slide)) "and neither moved the stage")

(let [m (sse/mark live)]
  (note `{"deck":"intro","slide":1,"text":"Two goes soon"}`)
  (assert (sse/until live m [`Two goes soon</textarea>`]) "A note is written while presenting")
  (def m (sse/mark live))
  (:save-presentation tree "intro"
                      @{:title "The Intro" :date "2026-02-23" :modified 2000000000
                        :slides @[[:section [:h1 "One"]]]})
  (assert (sse/until live m [`1 / 1` `Say hello first</textarea>` `Notes whose slide is gone`
                             `Was on slide 2` `Two goes soon` `Put on this slide`])
          "A note whose slide was taken out is kept aside, to be put somewhere"))
(let [orphan (get-in (:notes tree) ["intro" :orphans 0 :id])
      m (sse/mark live)]
  (note (string `{"deck":"intro","orphan":"` orphan `","slide":0}`))
  (assert (sse/until live m [`Say hello first` `Two goes soon</textarea>`])
          "and put on the slide on the stage, after its own note")
  (assert (empty? (get-in (:notes tree) ["intro" :orphans])) "It is an orphan no more"))

(let [m (sse/mark live)]
  (:build-failed tree "intro" {:file "intro.md" :line 7 :message "This code block is never closed."})
  (assert (sse/until live m [`1 / 1` `intro.md:7` `never closed`])
          "A broken save of the staged deck is said, and the slide stays"))

(let [p (client ;(server/host-port rpc) :test psk)
      [what at] (:ping p)]
  (assert (= :last-active what) "The presenter reports its last use")
  (assert (>= at (- (os/time) 1)) "and while a deck is on the stage, that is now")
  (:close p))

(let [m (sse/mark live)]
  (go `{"move":"close"}`)
  (assert (sse/until live m [`Nothing is on the stage` `Decks` `intro.md` `draft.md:3`])
          "Closing clears the stage, and brings the other decks back"))

(let [m (sse/mark live)]
  (:save-presentation tree "CULS-Backend"
                      @{:title "CULS Backend" :date "2024-02-26" :modified 1000000000
                        :sections @[@{:title "The Intro" :first 0 :count 2 :date "2024-02-26"}
                                    @{:title "Tools" :first 2 :count 1 :date "2024-02-27"}]
                        :slides @[[:section [:h1 "Hi"]] [:section [:h2 "Who"]]
                                  [:section [:h2 "Tools"]]]})
  (assert (sse/until live m [`intro.md` `CULS Backend` `3 slides in 2 sections`
                             `go(&quot;goto&quot;,&quot;CULS-Backend&quot;,2)` `Tools`])
          "A deck in sections offers each of them to start from, after the deck saved later"))
(let [m (sse/mark live)]
  (go `{"move":"goto","deck":"CULS-Backend","slide":2}`)
  (def sent (sse/until live m [`<h2>Tools</h2>` `Staged` `3 / 3` `Tools` `1 of 1`
                               `CULS Backend · Tools · 2024-02-27`]))
  (assert sent "and staging one of them says which section is on")
  (assert-not (string/find "intro.md" sent) "with the other decks put away"))

(let [m (sse/mark live)]
  (go `{"move":"close"}`)
  (assert (sse/until live m [`Nothing is on the stage`]) "Closing clears the podium"))

(assert (= 401 ((request "GET" (url "/attending")) :status))
        "The attending tab is the lecturer's alone")
(let [resp (request "GET" (url "/attending") :headers cookie)]
  (assert ((success-has? `>Stage</a>` `class="active"` `Nothing is attended` `function note(`)
            resp)
          "and says when nothing is attended")
  (assert-not (string/find "function go(" (resp :body)) "It moves no stage"))

(def attended (sse/open http "/attending/content" "abcd"))
(assert (sse/until attended 0 [`id="podium"` `Nothing is attended`])
        "Its stream starts with what is on now")
(let [m (sse/mark live)
      a (sse/mark attended)]
  (:save-presentation tree "elsewhere--course"
                      @{:title "Course" :modified 1500000000
                        :slides @[[:section [:h1 "Zero"]] [:section [:h1 "Four"]]]
                        :recorded @{:from "elsewhere" :presentation "course" :count 5
                                    :at @[0 4] :parts @[{} {}]}})
  (:attending/set tree "elsewhere" {:title "Course" :presentation "elsewhere--course" :slide 1})
  (def shown (sse/until attended a [`Course` `from elsewhere` `<h1>Four</h1>` `slide 5 of 5`
                                    `Notes` `data-ignore-morph`]))
  (assert shown "A lecture attended elsewhere shows on its recorded slide, with a note to write")
  (assert-not (string/find "Ctrl+←" shown) "whose keys move no deck of this lecturer's")
  (def staged (sse/until live m [`href="/attending"` `class="badge">1</span>`
                                 `Nothing is on the stage`
                                 `recorded from elsewhere · 2 of 5 slides`]))
  (assert staged "The stage tab says one is attended, and lists its recording")
  (assert-not (string/find "<h1>Four</h1>" staged) "but shows none of it"))
(let [a (sse/mark attended)]
  (:attending/set tree "elsewhere" false)
  (assert (sse/until attended a [`Nothing is attended`]) "Once it ends, nothing is attended"))
(sse/close attended)
(sse/close live)
(end-suite)
(os/exit 0)
