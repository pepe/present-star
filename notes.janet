(def- headings [:h1 :h2 :h3 :h4 :h5 :h6])

(defn- text-of
  "Every string in the htmlgen `node`, joined."
  [node]
  (cond
    (string? node) node
    (indexed? node) (string/join (map text-of node))
    ""))

(defn slide/heading
  "The text of the first heading on `slide`, or nil when it has none."
  [slide]
  (if-let [h (find |(and (indexed? $) (index-of (first $) headings)) slide)]
    (string/trim (text-of h))))

(defn- common
  ```
  The pairs of indexes, into `a` and into `b`, of the longest run of
  elements the two have in common, in order.
  ```
  [a b]
  (def n (length a))
  (def m (length b))
  (def w (inc m))
  (def lengths (array/new-filled (* (inc n) w) 0))
  (defn at [i j] (lengths (+ (* i w) j)))
  (loop [i :down-to [(dec n) 0]
         j :down-to [(dec m) 0]]
    (put lengths (+ (* i w) j)
         (if (deep= (a i) (b j))
           (inc (at (inc i) (inc j)))
           (max (at (inc i) j) (at i (inc j))))))
  (def pairs @[])
  (var i 0)
  (var j 0)
  (while (and (< i n) (< j m))
    (cond
      (deep= (a i) (b j)) (do (array/push pairs [i j]) (++ i) (++ j))
      (>= (at (inc i) j) (at i (inc j))) (++ i)
      (++ j)))
  pairs)

(defn slides/matched
  ```
  Where each slide of `old` went in `new`, as a table from its old index to
  its new one. A slide that went nowhere is not in it.

  Slides the same in both are matched as a diff matches lines. Between two
  of them, whatever is left on each side was edited there: when both sides
  have as many slides, they are the same slides edited in place; when they
  do not, a slide is taken for the one keeping its heading, or for none.
  ```
  [old new]
  (def n (length old))
  (def m (length new))
  # Decks are edited here and there, so what begins and ends both the same
  # is matched as it stands, and only what lies between is diffed.
  (var pre 0)
  (while (and (< pre n) (< pre m) (deep= (old pre) (new pre))) (++ pre))
  (var post 0)
  (while (and (< (+ pre post) n) (< (+ pre post) m)
              (deep= (old (- n post 1)) (new (- m post 1))))
    (++ post))
  (def pairs @[])
  (for i 0 pre (array/push pairs [i i]))
  (each [i j] (common (slice old pre (- n post)) (slice new pre (- m post)))
    (array/push pairs [(+ pre i) (+ pre j)]))
  (for k 0 post (array/push pairs [(+ (- n post) k) (+ (- m post) k)]))
  (def matched @{})
  (var oi -1)
  (var nj -1)
  (each [i j] [;pairs [n m]]
    (def olds (range (inc oi) i))
    (def news (range (inc nj) j))
    (if (= (length olds) (length news))
      (for k 0 (length olds) (put matched (olds k) (news k)))
      (each o olds
        (when-let [h (slide/heading (old o))
                   k (find-index |(= h (slide/heading (new $))) news)]
          (put matched o (news k))
          (array/remove news k))))
    (if (< i n) (put matched i j))
    (set oi i)
    (set nj j))
  matched)

(defn reanchored
  ```
  The `notes` on a deck's slides once the deck went from the `old` slides
  to the `new`, as `[notes orphans]`: the notes on the slides they belong
  to now, and the notes whose slide is gone.

  A note is `{:text :anchor}`, where the anchor is the slide it was written
  on. A slide that moved takes its note along, and so does one edited in
  place. When the old slides are not known -- a deck coming back after its
  file was gone -- a note finds only the very slide it was written on, the
  nearest one when that slide is there more than once. An orphan keeps the
  slide it was written on, and says where it `:was`.
  ```
  [notes old new]
  (def matched (if old (slides/matched old new) @{}))
  (def placed @{})
  (def astray @[])
  (defn place [n to]
    (put placed to @{:text ((notes n) :text) :anchor (new to)}))
  (each n (sorted (keys notes))
    (if-let [to (matched n)]
      (place n to)
      (array/push astray n)))
  (def orphans @[])
  (each n astray
    (def anchor ((notes n) :anchor))
    (def same (seq [i :range [0 (length new)]
                    :when (and (nil? (placed i)) (deep= anchor (new i)))]
                i))
    (if (empty? same)
      (array/push orphans @{:text ((notes n) :text) :anchor anchor :was n})
      (place n (first (sort-by |(math/abs (- $ n)) same)))))
  [placed orphans])

(defn- blank?
  [text]
  (empty? (string/trim text)))

(defn changed
  ```
  Changes `held`, the notes on `deck`, as `change` says, answering nil when
  it did, or why it would not.

  - `[:write id n text]` writes the note on slide `n`; a blank one removes it
  - `[:attach id orphan n]` puts an orphan's text on slide `n`, after what
    the slide's note says already
  - `[:drop id orphan]` forgets an orphan
  ```
  [held deck change]
  (defn orphan/at [oid] (find-index |(= oid ($ :id)) (held :orphans)))
  (match change
    [:write _ n text]
    (if-let [slide (get-in deck [:slides n])]
      (do (put (held :slides) n (if-not (blank? text) @{:text text :anchor slide}))
        nil)
      "There is no such slide.")
    [:attach _ oid n]
    (let [i (orphan/at oid)
          slide (get-in deck [:slides n])]
      (cond
        (nil? i) "There is no such note."
        (nil? slide) "There is no such slide."
        (let [text ((get-in held [:orphans i]) :text)
              before (get-in held [:slides n :text])]
          (put (held :slides) n
               @{:text (if before (string before "\n\n" text) text) :anchor slide})
          (array/remove (held :orphans) i)
          nil)))
    [:drop _ oid]
    (if-let [i (orphan/at oid)]
      (do (array/remove (held :orphans) i) nil)
      "There is no such note.")
    "Unknown change."))

(defn projected
  ```
  The notes as the presenter is given them: by deck, the text on each
  slide, and the orphans with the slides they were written on.
  ```
  [notes]
  (tabseq [[id held] :pairs notes]
    id @{:slides (tabseq [[n note] :pairs (held :slides)] n (note :text))
         :orphans (held :orphans)}))
