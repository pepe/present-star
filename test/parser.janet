(use spork/test ../present-star/parser)

(start-suite "docs")
(assert-docs "../present-star/parser")
(start-suite)
(assert
  (=
    [:main
     [:header [:h1 "Test presentation"] [:nav]]
     [:section
      [:h1 "Title"]]]
    (parse-deck "author: Pp\ndate:2024/10/26\ntitle: Test presentation\n---\n# Title")))
(end-suite)
