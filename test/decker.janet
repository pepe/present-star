(def conf-file "test/conf.decker.test.jdn")
(os/setenv "CONF" conf-file)
(use spork/test /environment /schema gp/net/rpc)
(import /decker)

(start-suite :docs)
(assert-docs "/decker")
(end-suite)

(start-suite :build)
(assert (= "intro" (decker/deck/id-of "intro.md")) "A deck is named after its file")
(assert (= "CULS Backend 2025" (decker/deck/title-of "CULS-Backend-2025.md"))
        "and titled after it, dashes as spaces")
(assert (= "data modeling" (decker/deck/title-of "data_modeling.md")) "underscores too")
(assert (decker/source? ["README.md"] "intro.md") "A Markdown file is a deck")
(assert-not (decker/source? ["README.md"] "README.md") "unless it is ignored")
(assert-not (decker/source? [] ".#intro.md") "Editors' lock files are not decks")
(assert-not (decker/source? [] "notes.txt") "Nor is anything but Markdown")
(let [[what id deck] (decker/build "My-Deck.md" "title: First part\n---\n# One")]
  (assert (= [:save "My-Deck"] [what id]) "A good deck is saved")
  (assert (= "My Deck" (deck :title)) "titled after its file")
  (assert (= "First part" (get-in deck [:sections 0 :title])) "with its sections as written"))
(let [[_ _ deck] (decker/build "a.md" "title: A\n---\n# One" 1790000000)]
  (assert (= 1790000000 (deck :modified)) "and stamped with when its file was saved"))
(let [[what id err] (decker/build "b.md" "title: B\nbroken\n---")]
  (assert (= [:failed "b"] [what id]) "A broken deck fails")
  (assert (= "b.md" (err :file)) "naming its file")
  (assert (= 2 (err :line)) "and the line it broke at"))
(end-suite)

(def tree-conf (parse (slurp "test/conf.tree.test.jdn")))
(def tree (client ;(server/host-port (tree-conf :rpc)) :test (tree-conf :psk)))

(def dir (path/join (os/getenv "TEMP" (os/getenv "TMPDIR" "/tmp"))
                    (string "present-star-decks-" (os/time))))
(os/mkdir dir)
(defn write [file & lines] (spit (path/join dir file) (string/join lines "\n")))
(defn eventually
  "Waits up to two seconds for `f` to hold, answering what it answered."
  [f]
  (var res nil)
  (var n 0)
  (while (and (not (set res (f))) (< n 40)) (ev/sleep 0.05) (++ n))
  res)
(defn deck [id] (get (:presentations tree) id))
(defn failure [id] (get (:errors tree) id))

# A deck left in the tree from a file removed while the decker was down.
(:save-presentation tree "stale" @{:title "Stale" :slides @[[:section]]})
(write "intro.md" "title: The Intro" "author: Josef" "---" "## One" "---" "## Two")
(write "README.md" "# Not a deck")

(put decker/initial-state :sources dir)
(ev/go decker/main)

(start-suite :follow)
(assert (eventually |(deck "intro")) "A deck in the sources reaches the tree")
(assert (= 2 (length ((deck "intro") :slides))) "with all its slides")
(assert (= (os/stat (path/join dir "intro.md") :modified) ((deck "intro") :modified))
        "stamped with when its file was saved")
(assert (eventually |(nil? (deck "stale"))) "A deck whose file is gone is forgotten")
(assert (nil? (deck "README")) "The README is left alone")

(let [before ((:snapshot tree [:presentations]) :revision)]
  (ev/sleep 0.5)
  (assert (= before ((:snapshot tree [:presentations]) :revision))
          "A deck nobody touched is not built again"))

(write "intro.md" "title: The Intro" "---" "## One" "---" "## Two" "---" "## Three")
(assert (eventually |(= 3 (length ((deck "intro") :slides)))) "A saved change reaches the tree")

(write "intro.md" "title: The Intro" "oops" "---" "## One")
(assert (eventually |(failure "intro")) "A broken save is reported")
(assert (= 2 ((failure "intro") :line)) "at its line")
(assert (= 3 (length ((deck "intro") :slides)))
        "and the deck built last stays, slides and all")

(write "intro.md" "title: The Intro" "---" "## Fixed")
(assert (eventually |(nil? (failure "intro"))) "Fixing it clears the error")
(assert (= 1 (length ((deck "intro") :slides))) "and builds the fixed deck")

(write "code.md" "title: Code" "---" "```janet" "(print 1)" "---" "```")
(assert (eventually |(deck "code")) "A deck with code reaches the tree")
(assert (= 1 (length ((deck "code") :slides))) "and its --- inside the code is code")

(os/rm (path/join dir "intro.md"))
(assert (eventually |(nil? (deck "intro"))) "A deleted file removes its deck")
(end-suite)

(each f (os/dir dir) (os/rm (path/join dir f)))
(os/rmdir dir)
(os/exit 0)
