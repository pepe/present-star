(use ./parser spork)
(temple/add-loader)
(import /templates/app)

(defn main
  [_ title & files]
  (app/render :title title
              :decks (seq [file :in files]
                       (htmlgen/html (parse-deck (slurp file))))))
