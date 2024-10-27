(use spork/test)

(start-suite "docs")
(assert-docs "../present-star/parser")
(end-suite)
(start-suite)
(import ../present-star/parser :prefix "")
(assert
  (=
    [:main
     [:section
      [:h1 "Title"]]
     [:section
      [:h2 "Subtitle"]]
     [:section
      [:h1 "Bullet Title"]
      [:ul
       [:li "Bullet 1"]
       [:li [:a {:href "http://google.com" :target "_blank"} "Bullet 2"]]]]
     [:section
      [:img {:alt "Some image" :src "http://fotos.com/1"}]]
     [:section
      [:quote "Smart word"]]
     [:footer [:h1 "Test presentation"] [:span "2024/10/26"] [:span "Pp"]]]
    (parse-deck "author: Pp\ndate:2024/10/26\ntitle: Test presentation\n---\n# Title\n---\n## Subtitle\n---\n# Bullet Title\n* Bullet 1\n* Bullet 2[http://google.com]\n---\n!Some image[http://fotos.com/1]\n---\n> Smart word")))
(end-suite)
