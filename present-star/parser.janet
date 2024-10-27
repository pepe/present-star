(use spork gp/data/schema)

(defmacro </>
  "Captures one elemnt"
  [el]
  ~(fn ,(symbol el) [& c] [,el ;c]))

(defn parse-deck
  "Parses deck string"
  [str]
  (defn <footer/>
    [& fm-arr]
    (def h (table ;(flatten fm-arr)))
    [:footer
     [:h1 (h "title")]
     [:span (h "date")]
     [:span (h "author")]])
  (defn <a/>
    [label href]
    [:a {:href href :target "_blank"} label])
  (defn <img/>
    [alt src]
    [:img {:src src :alt alt}])
  (def grammar
    ~{:eol (+ "\n" "\r\n")
      :2eol (* :eol :eol)
      :rest (cmt '(to -1) ,(</> :error))
      :div "---"
      :kv (group (* '(some (if-not (+ :eol ":") 1)) ":" :s* '(to :eol)))
      :frontmatter (cmt (some (* :kv :eol)) ,<footer/>)
      :slide-end (+ (* (? :eol) :div (? :eol)) -1)
      :h1 (cmt (* "#" :s* '(to (+ :eol -1))) ,(</> :h1))
      :h2 (cmt (* "##" :s* '(to (+ :eol -1))) ,(</> :h2))
      :li (cmt (* "*" :s* '(to (+ :eol -1))) ,(</> :li))
      :li-a (cmt (cmt (* "*" :s* '(some (if-not (+ :eol "[") 1)) "[" '(to "]") "]" (+ :eol -1)) ,<a/>) ,(</> :li))
      :ul (cmt (some (* (+ :li-a :li) (? :eol))) ,(</> :ul))
      :img (cmt (* "!" :s* '(some (if-not (+ :eol "[") 1)) "[" '(to "]") "]" (+ :eol -1)) ,<img/>)
      :quote (cmt (* ">" :s* '(to (+ :eol -1))) ,(</> :quote))
      :slide (cmt (* (some (* (+ :h2 :h1 :ul :img :quote) (? :eol))) :slide-end) ,(</> :section))
      :slides (some :slide)
      :main (* :frontmatter :div :eol :slides)})
  (def [f & s] (peg/match grammar str))
  [:main ;s f])
