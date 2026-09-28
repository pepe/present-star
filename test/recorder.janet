(def tree-conf (parse (slurp "test/conf.tree.test.jdn")))
(os/setenv "CONF" "test/conf.recorder.test.jdn")
(use spork/test /environment /schema gp/net/rpc)
(import gp/net/server)
(import /recorder)

(start-suite :docs)
(assert-docs "/recorder")
(end-suite)

(start-suite :clean)
(defn clean [node] (recorder/slide/clean node))
(def plain [:section [:h2 "Hi"] [:p "text " [:strong "bold"] " and " [:em "not"]]
            [:ul [:li "one"] [:li [:code "two"]]] [:blockquote [:p "said"]]])
(assert (deep= plain (clean plain)) "A slide as the parser makes it is kept")
(assert (deep= [:section [:p "go"]] (clean [:section [:p "go"] [:script "alert(1)"]]))
        "A script is left out")
(assert (deep= [:section [:p "hi"]] (clean [:section [:p {:onclick "steal()"} "hi"]]))
        "and so is a handler")
(assert (deep= [:a {:href "https://janet-lang.org" :target "_blank" :rel "noopener"} "Janet"]
               (clean [:a {:href "https://janet-lang.org" :onmouseover "x()"} "Janet"]))
        "A link to the web is kept, and opens elsewhere")
(assert (deep= [:span "here"] (clean [:a {:href "javascript:steal()"} "here"]))
        "A link to anywhere else is its text")
(assert (deep= [:img {:src "https://example.org/a.png" :alt "a"}]
               (clean [:img {:src "https://example.org/a.png" :alt "a" :onerror "x()"}]))
        "An image from the web is kept")
(assert (nil? (clean [:img {:src "images/a.png"}])) "and one from the other thicket's own disk is not")
(assert (deep= [:pre [:code {:class "language-janet"} "(+ 1 2)"]]
               (clean [:pre [:code {:class "language-janet"} "(+ 1 2)"]]))
        "Code keeps its language")
(assert (deep= [:code "x"] (clean [:code {:class "language-x\" onload=\"y()"} "x"]))
        "and nothing that only looks like one")
(assert (nil? (clean (fn [] :called))) "Nothing but plain data gets through")
(assert (nil? (clean @{:tag :script})) "not even a table")
(end-suite)

(start-suite :recorded)
(defn live [n content section]
  {:presentation "course" :title "Course" :slide n :count 5 :section section :content content})
(def s0 [:section [:h1 "Zero"]])
(def s2 [:section [:h1 "Two"]])
(def s4 [:section [:h1 "Four"]])
(def d1 (recorder/recorded nil "elsewhere" (live 2 s2 "Intro") s2))
(assert (deep= @[2] (get-in d1 [:recorded :at])) "A recording begins with the slide shown")
(def d2 (recorder/recorded d1 "elsewhere" (live 0 s0 "Intro") s0))
(assert (deep= @[0 2] (get-in d2 [:recorded :at])) "and keeps the order of the lecturer's deck")
(assert (deep= @[s0 s2] (d2 :slides)) "whatever order the slides were shown in")
(assert (nil? (recorder/recorded d2 "elsewhere" (live 2 s2 "Intro") s2))
        "A slide shown again as it was changes nothing")
(def s2b [:section [:h1 "Two, fixed"]])
(def d3 (recorder/recorded d2 "elsewhere" (live 2 s2b "Intro") s2b))
(assert (deep= @[s0 s2b] (d3 :slides)) "and one the lecturer changed takes the old one's place")
(def d4 (recorder/recorded d3 "elsewhere" (live 4 s4 "Tools") s4))
(assert (deep= @[["Intro" 0 2] ["Tools" 2 1]]
               (map |[($ :title) ($ :first) ($ :count)] (d4 :sections)))
        "The sections are what each slide said it was part of")
(assert (deck? d4) "A recording is a deck like any other")
(assert (= "elsewhere--course" (recorder/recording/id "elsewhere" "course"))
        "It is named after where it is from, and its deck there")
(assert (deck/id? (recorder/recording/id "elsewhere" "../etc")) "and the name never names another place")
(end-suite)

(setdyn :ctx ctx)
(def tree (client ;(server/host-port (tree-conf :rpc)) :test (tree-conf :psk)))

# Elsewhere's relay, as this thicket's recorder meets it: known by its key,
# and admitting this thicket by its own. It answers with whatever the test
# puts on `lives`, one ask at a time.
(def lives (ev/chan 8))
(def remote
  (identity/keypair {:public "091db711ee01cd6c96e40c075a0b0311f948a34e947dbd2d2d52aaa6b3cf7002"
                     :secret "2a07bc83c663dba6ea01c61019f2340e5da7a28760b7fdb89d0c3c6b859d7e42"}))
(var asked 0)
(ev/spawn
  (def sc (ev/chan))
  (def handling
    (on-connection
      @{:psk relay/psk
        :keypair remote
        :allowed [(key/bin "af48aff4437b39038ce55db9237739f47e6b050b954ae09bea7a2d6628fad926")]
        :live/after (fn [_ _] {:mark (++ asked) :live (ev/take lives)})}))
  (server/start sc "localhost" 5553)
  (supervisor sc handling))

(defn eventually
  "Waits up to two seconds for `f` to hold, answering what it answered."
  [f]
  (var res nil)
  (var n 0)
  (while (and (not (set res (f))) (< n 40)) (ev/sleep 0.05) (++ n))
  res)
(defn recording [] (get (:presentations tree) "elsewhere--course"))
(defn attended [] (get (:attending tree) "elsewhere"))

(ev/go recorder/main)
(ev/sleep 0.5)

(start-suite :following)
(ev/give lives {:presentation "course" :title "Course"})
(assert (eventually |(deep= {:title "Course"} (attended)))
        "A lecture staged elsewhere is attended by its title")
(assert (nil? (recording)) "and nothing is recorded of it yet")
(ev/give lives {:presentation "course" :title "Course" :slide 1 :count 3 :section "Intro"
                :content [:section [:h1 "One"] [:script "steal()"]]})
(assert (eventually recording) "A slide shown elsewhere is recorded in this tree")
(assert (deep= @[[:section [:h1 "One"]]] ((recording) :slides))
        "as a slide of ours, and nothing else")
(assert (deep= {:title "Course" :presentation "elsewhere--course" :slide 0} (attended))
        "and attended on the slide it is in the recording")
(assert (= :ok ((:notes/change tree :write "elsewhere--course" 0 "Ask about one") :status))
        "A note is written on what is attended")
(ev/give lives {:presentation "course" :title "Course" :slide 0 :count 3 :section "Intro"
                :content [:section [:h1 "Zero"]]})
(assert (eventually |(= 2 (length ((recording) :slides)))) "The recording grows")
(assert (= "Ask about one" (get-in (:notes tree) ["elsewhere--course" :slides 1]))
        "and the note stays with its slide")
(ev/give lives false)
(assert (eventually |(nil? (attended))) "When the lecture ends elsewhere, nothing is attended")
(assert (recording) "and the recording stays")
(end-suite)
(os/exit 0)
