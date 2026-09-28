(def- frontmatter/kv
  (peg/compile
    ~(* (<- (some (if-not ":" 1))) ":" (any :s) (<- (any 1)))))

(def- heading
  (peg/compile ~(* (<- (between 1 6 "#")) (not "#") (any " ") (<- (any 1)))))

(def- bullet
  (peg/compile ~(* (set "*-+") (some " ") (<- (any 1)))))

(def- numbered
  (peg/compile ~(* (some :d) "." (some " ") (<- (any 1)))))

(def- quote-line
  (peg/compile ~(* ">" (any " ") (<- (any 1)))))

(def- image
  (peg/compile
    ~(+ (* "![" (<- (to "]")) "](" (<- (to ")")) ")" -1)
        # The form present-star has always read: `!alt[src]`.
        (* "!" (not "[") (<- (some (if-not "[" 1))) "[" (<- (to "]")) "]" -1))))

(def- legacy-link
  ```
  A whole line that is `text[url]`, the only link present-star used to read.

  Kept apart from the inline links because it is not one: the brackets hold
  the address rather than the text, and only a line ending in them means it.
  ```
  (peg/compile
    ~(* (<- (some (if-not "[" 1))) "["
        (<- (* (+ "http://" "https://" "/" "./") (to "]"))) "]" -1)))

(defn- <a/>
  [text href]
  [:a {:href href :target "_blank" :rel "noopener"} text])

(def- inline
  (peg/compile
    ~{:code (/ (* "`" '(to "`") "`") ,|[:code $])
      :strong (/ (* "**" '(to "**") "**") ,|[:strong $])
      :em (/ (* "*" (not (set " *")) '(to "*") "*") ,|[:em $])
      :link (/ (* "[" '(to "]") "](" '(to ")") ")") ,<a/>)
      :text '(some (if-not (set "`*[") 1))
      :main (any (+ :code :strong :em :link :text '1))}))

(defn- join-text
  "Merges neighbouring strings, which the inline grammar splits at every
  character it had to give back."
  [nodes]
  (def out @[])
  (each node nodes
    (if (and (string? node) (string? (last out)))
      (put out (dec (length out)) (string (last out) node))
      (array/push out node)))
  out)

(defn inline/parse
  "Parses one line of slide text into htmlgen nodes."
  [text]
  (if-let [[text-part href] (peg/match legacy-link text)]
    @[(<a/> (string/trimr text-part) href)]
    (join-text (peg/match inline text))))

(defn- fail
  [line message]
  (error {:line line :message message}))

(defn- fence?
  [text]
  (string/has-prefix? "```" text))

(defn- lines/of
  ```
  Numbered lines of `source`, without their line endings.

  CRLF and LF are both what a deck may be saved with; the course decks are
  CRLF, and a parser that only knew LF read their frontmatter values with a
  carriage return at the end.
  ```
  [source]
  (def text (if (string/has-prefix? "\xEF\xBB\xBF" source)
              (string/slice source 3)
              source))
  (seq [[i line] :pairs (string/split "\n" text)]
    [(inc i) (string/trimr line)]))

(defn- sections/split
  ```
  Splits numbered `lines` into sections at the `===` lines.

  A `===` inside a code block is code, like a `---` is. Sections with
  nothing in them are dropped: a deck ending with `===` does not mean one
  more, empty section.
  ```
  [lines]
  (def sections @[@[]])
  (var fenced false)
  (each [n text] lines
    (cond
      fenced (do (if (fence? text) (set fenced false))
               (array/push (last sections) [n text]))
      (fence? text) (do (set fenced true)
                      (array/push (last sections) [n text]))
      (= text "===") (array/push sections @[])
      (array/push (last sections) [n text])))
  (filter |(some (fn [[_ text]] (not (empty? text))) $) sections))

(defn- frontmatter
  ```
  Reads the frontmatter a section opens with, returning it and the index
  of the line after it. The frontmatter may be opened by a `---` of its
  own, as every section after the first is.
  ```
  [lines]
  (def meta @{})
  (var at 0)
  (var closed false)
  (while (and (< at (length lines)) (empty? ((lines at) 1))) (++ at))
  (if (and (< at (length lines)) (= "---" ((lines at) 1))) (++ at))
  (while (and (not closed) (< at (length lines)))
    (def [n text] (lines at))
    (++ at)
    (cond
      (= text "---") (set closed true)
      (empty? text) nil
      (if-let [[k v] (peg/match frontmatter/kv text)]
        (put meta (keyword (string/trim k)) (string/trim v))
        (fail n (string "Expected `key: value` in the frontmatter, or `---` "
                        "to end it, found `" text "`.")))))
  (unless closed
    (fail ((last lines) 0) "The frontmatter has to end with a `---` line."))
  (when (empty? (get meta :title ""))
    (fail ((first lines) 0) "The frontmatter needs a `title`."))
  [meta at])

(defn- slides/split
  ```
  Splits the lines after the frontmatter into slides at the `---` lines.

  A `---` inside a code block is code, so the fences are followed here as
  well as in the blocks. Empty slides at the end are dropped: a deck ending
  with a separator does not mean one more, blank slide.
  ```
  [lines from]
  (def slides @[@[]])
  (var fenced nil)
  (loop [i :range [from (length lines)]
         :let [[n text] (lines i)]]
    (cond
      fenced (do (if (fence? text) (set fenced nil))
               (array/push (last slides) [n text]))
      (fence? text) (do (set fenced n)
                      (array/push (last slides) [n text]))
      (= text "---") (array/push slides @[])
      (array/push (last slides) [n text])))
  (when fenced
    (fail fenced "This code block is never closed."))
  (while (and (not (empty? slides))
              (all |(empty? ($ 1)) (last slides)))
    (array/pop slides))
  slides)

(defn- block/start?
  "Whether `text` begins a block of its own, ending a paragraph."
  [text]
  (or (empty? text)
      (fence? text)
      (peg/match heading text)
      (peg/match bullet text)
      (peg/match numbered text)
      (peg/match quote-line text)
      (peg/match image text)))

(defn- list/items
  "Collects the items of one list starting at `at`, joining continuations."
  [lines at item-peg]
  (def items @[])
  (var i at)
  (var going true)
  (while (and going (< i (length lines)))
    (def [_ text] (lines i))
    (if-let [[item] (peg/match item-peg text)]
      (do (array/push items item) (++ i))
      (if (and (not (empty? items))
               (string/has-prefix? " " text)
               (not (block/start? (string/triml text))))
        (do (put items (dec (length items))
                 (string (last items) " " (string/trim text)))
          (++ i))
        (set going false))))
  [items i])

(defn- slide/blocks
  "Parses the lines of one slide into htmlgen blocks."
  [lines]
  (def blocks @[])
  (var i 0)
  (while (< i (length lines))
    (def [n text] (lines i))
    (cond
      (empty? text) (++ i)

      (fence? text)
      (let [lang (string/trim (string/slice text 3))
            body @[]]
        (++ i)
        (while (not (fence? ((lines i) 1)))
          (array/push body ((lines i) 1))
          (++ i))
        (++ i)
        (array/push blocks
                    [:pre (if (empty? lang)
                            [:code (string/join body "\n")]
                            [:code {:class (string "language-" lang)}
                             (string/join body "\n")])]))

      (peg/match heading text)
      (let [[hashes title] (peg/match heading text)]
        (array/push blocks [(keyword "h" (length hashes)) ;(inline/parse title)])
        (++ i))

      (peg/match image text)
      (let [[alt src] (peg/match image text)]
        (array/push blocks [:img {:src src :alt alt}])
        (++ i))

      (peg/match bullet text)
      (let [[items next] (list/items lines i bullet)]
        (array/push blocks [:ul ;(seq [item :in items] [:li ;(inline/parse item)])])
        (set i next))

      (peg/match numbered text)
      (let [[items next] (list/items lines i numbered)]
        (array/push blocks [:ol ;(seq [item :in items] [:li ;(inline/parse item)])])
        (set i next))

      (peg/match quote-line text)
      (let [said @[]]
        (while (and (< i (length lines)) (peg/match quote-line ((lines i) 1)))
          (array/push said (first (peg/match quote-line ((lines i) 1))))
          (++ i))
        (array/push blocks
                    [:blockquote [:p ;(inline/parse (string/join said " "))]]))

      (let [said @[text]]
        (++ i)
        (while (and (< i (length lines)) (not (block/start? ((lines i) 1))))
          (array/push said (string/trim ((lines i) 1)))
          (++ i))
        (array/push blocks [:p ;(inline/parse (string/join said " "))]))))
  blocks)

(defn parse-deck
  ```
  Parses the Markdown `source` of one deck, called `title` -- by default
  the title of its first section.

  A deck is one or more sections, parted by `===` lines, and each section
  opens with a frontmatter of its own. Its slides are one run, counted
  across the sections, because a lecture moves through them as one;
  each of the `:sections` says where its slides begin, how many there
  are, and its `:title`, `:author`, `:date` and whole frontmatter under
  `:meta`. The deck's `:author` and `:date` are its first section's.

  What it cannot read it refuses, raising `{:line :message}` -- never a
  deck with its slides cut short, which is what the old parser handed over
  whenever a line surprised it.
  ```
  [source &opt title]
  (def slides @[])
  (def sections @[])
  (each lines (sections/split (lines/of source))
    (def [meta at] (frontmatter lines))
    (def these (seq [slide :in (slides/split lines at)]
                 [:section ;(slide/blocks slide)]))
    (array/push sections @{:title (meta :title)
                           :author (meta :author)
                           :date (meta :date)
                           :meta meta
                           :first (length slides)
                           :count (length these)})
    (array/concat slides these))
  (when (empty? sections)
    (fail 1 "A deck opens with a frontmatter, and this one is empty."))
  (def opening (first sections))
  @{:title (or title (opening :title))
    :author (opening :author)
    :date (opening :date)
    :meta (opening :meta)
    :sections sections
    :slides slides})
