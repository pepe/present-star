(use spork/test)
(import spork/htmlgen :as hg)
(import /parser)

(start-suite :docs)
(assert-docs "/parser")
(end-suite)

(defn deck [& lines] (parser/parse-deck (string/join lines "\n")))
(defn slides [d] (d :slides))
(defn refused [source]
  (match (protect (parser/parse-deck source))
    [false err] err
    [true d] (errorf "parsed what should be refused: %q" d)))

(start-suite :course-format)
# The course decks are saved with CRLF, bullets both ways, and links
# followed by more text on the same line.
(let [d (parser/parse-deck
          (string/join
            ["author: Josef Pospíšil" "date: 2026-02-23" "title: The Intro" "---"
             "## History of Backend Development" "---"
             "## Good Old Friends" "* Hello again!" "* Black Swan Song" "---"
             "## Links" "- [Janet](https://janet-lang.org/) Default password is testist."
             "- [Interstudy](https://github.com/pepe/interstudy)" ""]
            "\r\n"))]
  (assert (= "The Intro" (d :title)) "The title is read without the CR")
  (assert (= "Josef Pospíšil" (d :author)) "The author keeps its accents")
  (assert (= "2026-02-23" (d :date)) "The date is read")
  (assert (= 3 (length (slides d))) "Every slide is kept")
  (assert (deep= [:section [:h2 "Good Old Friends"]
                  [:ul [:li "Hello again!"] [:li "Black Swan Song"]]]
                 ((slides d) 1))
          "Star bullets make a list")
  (def links ((slides d) 2))
  (assert (deep= [:li [:a {:href "https://janet-lang.org/" :target "_blank" :rel "noopener"}
                       "Janet"]
                  " Default password is testist."]
                 (get-in links [2 1]))
          "A dash bullet keeps the text after its link"))
(end-suite)

(start-suite :code)
(let [d (deck "title: Code" "---"
              "## Janet"
              "```janet"
              "(defn main [& args]"
              "  # not a heading"
              "  * not a bullet"
              "---"
              "  (print \"<b>hi</b>\"))"
              "```"
              "After the code"
              "---"
              "## Next")]
  (assert (= 2 (length (slides d))) "A --- inside a code block does not split the slide")
  (def [_ _ pre p] ((slides d) 0))
  (assert (deep= [:pre [:code {:class "language-janet"}
                        "(defn main [& args]\n  # not a heading\n  * not a bullet\n---\n  (print \"<b>hi</b>\"))"]]
                 pre)
          "The code is kept verbatim, indentation and all, with its language")
  (assert (deep= [:p "After the code"] p) "Text after the block is a paragraph")
  (assert (string/find "&lt;b&gt;hi&lt;/b&gt;" (hg/html pre))
          "Code is escaped when rendered"))
(let [d (deck "title: Code" "---" "```" "plain" "```")]
  (assert (deep= [:section [:pre [:code "plain"]]] ((slides d) 0))
          "A block without a language has no class"))
(let [err (refused (string/join ["title: Code" "---" "## Janet" "```janet" "(print 1)"] "\n"))]
  (assert (= 4 (err :line)) "An unclosed block is reported where it opens")
  (assert (string/find "never closed" (err :message)) "and says so"))
(let [d (deck "title: Inline" "---" "Use `defn` **now**, *really*.")]
  (assert (deep= [:section [:p "Use " [:code "defn"] " " [:strong "now"] ", " [:em "really"] "."]]
                 ((slides d) 0))
          "Inline code, strong and emphasis"))
(end-suite)

(start-suite :nothing-lost)
# Every one of these made the old parser drop slides without a word.
(each [what source]
  [["a blank line after ---" ["title: T" "---" "# A" "---" "" "# B" "---" "# C"]]
   ["a blank line inside a slide" ["title: T" "---" "# A" "" "* x" "---" "# B" "---" "# C"]]
   ["two trailing newlines" ["title: T" "---" "# A" "---" "# B" "---" "# C" "" ""]]
   ["a closing separator" ["title: T" "---" "# A" "---" "# B" "---" "# C" "---" ""]]
   ["a paragraph" ["title: T" "---" "# A" "Some text" "---" "# B" "---" "# C"]]
   ["dash bullets" ["title: T" "---" "# A" "- x" "- y" "---" "# B" "---" "# C"]]]
  (assert (= 3 (length (slides (deck ;source)))) (string "Nothing is lost to " what)))
(let [d (deck "title: T" "---" "# A" "---" "---" "# C")]
  (assert (deep= [:section] ((slides d) 1)) "An empty slide in the middle is kept"))
(end-suite)

(start-suite :blocks)
(let [[s] (slides (deck "title: T" "---"
                        "### Small" "1. one" "2. two" "> said" "> twice"
                        "![A cat](/cat.png)" "!A dog[/dog.png]"
                        "A paragraph" "over two lines"))]
  (assert (deep= [:section
                  [:h3 "Small"]
                  [:ol [:li "one"] [:li "two"]]
                  [:blockquote [:p "said twice"]]
                  [:img {:src "/cat.png" :alt "A cat"}]
                  [:img {:src "/dog.png" :alt "A dog"}]
                  [:p "A paragraph over two lines"]]
                 s)
          "Headings, numbered lists, quotes, both image forms and paragraphs"))
(let [[s] (slides (deck "title: T" "---" "* one" "  continued" "* two"))]
  (assert (deep= [:section [:ul [:li "one continued"] [:li "two"]]] s)
          "An indented line continues its bullet"))
(end-suite)

(start-suite :sections)
# The course decks: sections parted by `===`, each opening with a
# frontmatter of its own, the later ones behind a `---`.
(let [d (parser/parse-deck
          (string/join
            ["author: Josef Pospíšil" "date: 2024-02-26" "title: The Intro" "---"
             "## One" "---" "" "## Two" "" "==="
             "---" "author: Josef Pospíšil" "date: 2024-02-27" "title: Tools" "---"
             "" "## Three" "===" ""]
            "\r\n")
          "CULS Backend 2025")]
  (assert (= "CULS Backend 2025" (d :title)) "A deck is called what it is given")
  (assert (= 3 (length (slides d))) "Its slides run on across the sections")
  (assert (deep= [:section [:h2 "Three"]] ((slides d) 2)) "in the order they are written")
  (assert (= 2 (length (d :sections))) "A trailing === adds no empty section")
  (let [[intro tools] (d :sections)]
    (assert (= ["The Intro" 0 2] [(intro :title) (intro :first) (intro :count)])
            "A section says its title, where it starts and how long it is")
    (assert (= ["Tools" "2024-02-27" 2 1]
               [(tools :title) (tools :date) (tools :first) (tools :count)])
            "and has a frontmatter of its own")
    (assert (= "2024-02-26" (d :date)) "The deck is dated by its first section")))
(let [d (deck "title: Code" "---" "```" "===" "```" "---" "# Two")]
  (assert (= 1 (length (d :sections))) "A === inside a code block is code")
  (assert (= 2 (length (slides d))) "and parts nothing"))
(let [err (refused (string/join ["title: A" "---" "# One" "===" "---" "# Two" "---"] "\n"))]
  (assert (= 6 (err :line)) "A section without a frontmatter is refused where it starts"))
(assert (= "One" ((deck "title: One" "---" "# A") :title))
        "A deck given no title is called after its first section")
(end-suite)

(start-suite :legacy)
(let [d (parser/parse-deck (slurp "test/decks/legacy.md"))]
  (assert (= "Test presentation" (d :title)) "The old test deck still reads")
  (assert (= 5 (length (slides d))) "with all five slides")
  (assert (deep= [:li [:a {:href "http://google.com" :target "_blank" :rel "noopener"}
                       "Bullet 2"]]
                 (get-in (slides d) [2 1 2]))
          "and its `text[url]` link"))
(end-suite)

(start-suite :refusals)
(let [err (refused "title: T\nnot a pair\n---\n# A")]
  (assert (= 2 (err :line)) "A frontmatter line without a colon is named")
  (assert (string/find "not a pair" (err :message)) "and quoted"))
(assert (string/find "title" ((refused "author: me\n---\n# A") :message))
        "A deck needs a title")
(assert (string/find "---" ((refused "title: T\n# A") :message))
        "The frontmatter has to be closed")
(assert (= 1 ((refused "## Slide first\n---") :line))
        "A deck without frontmatter is refused at its first line")
(end-suite)

(start-suite :escaping)
(let [[s] (slides (deck "title: T" "---" "# <script>alert(1)</script>"))]
  (assert (string/find "&lt;script&gt;" (hg/html s)) "Slide text cannot inject HTML"))
(end-suite)
