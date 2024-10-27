(use spork)
(temple/add-loader)
(import /templates/app)
(import ./parser)

(defn main
  "Render final presentation file with `title` from `files`"
  [_ title & files]
  (app/render :title title
              :decks (seq [file :in files]
                       (htmlgen/html (parser/parse-deck (slurp file))))))
