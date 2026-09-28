(use /environment /schema)
(import twm/dev :only [demiurge/watch] :prefix "")

(def conf
  "Navigation to initial state in config"
  ((=>symbiont/initial-state :demiurge) compile-config))

(defn main
  ```
  Runs the thicket for development, raising every peer and restarting the
  lot whenever a Janet source changes. Decks and the stylesheet are not
  sources: the decker rebuilds decks as they are saved, and the stylesheet
  is served fresh.

  `test` runs the suite once, `test/watch` again on every change.
  ```
  [_ & args]
  (demiurge/watch conf args))
