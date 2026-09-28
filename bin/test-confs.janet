(os/setenv "CONF" "test/conf.test.jdn")
(use /schema /environment)

(def symbionts
  "Every symbiont whose derived config the tests hold as a fixture."
  [:demiurge :tree :decker :presenter :presenter/sentry :watcher])

(defn fixture
  ```
  The file holding `symbiont`'s derived config. A `/` in its name is a
  `__` in the file's, as it is in every file twm names after a peer, or the
  sentry's would be a file in a directory of the presenter's.
  ```
  [symbiont]
  (string "test/conf." (peer/file-name symbiont) ".test.jdn"))

(defn main
  ```
  Regenerates `test/conf.<symbiont>.test.jdn` from `test/conf.test.jdn`.

  They are what each symbiont derives from the thicket's config, kept as
  fixtures that `test/environment.janet` holds the navigation to. Run this
  after any change to the test config. `%p` keeps them sorted and indented,
  so a change reads as a diff rather than as one rewritten line.
  ```
  [&]
  (each sym symbionts
    (def file (fixture sym))
    (spit file (string/format "%p" ((=>symbiont/initial-state sym) compile-config)))
    (print file)))
