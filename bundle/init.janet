(use spork/declare-cc)
(import twm/app :only [aether/read-message] :prefix "")

(declare-project :name "present-star")

(declare-executable
  :name "tree"
  :entry "tree.janet")

(declare-executable
  :name "decker"
  :entry "decker.janet")

(declare-executable
  :name "presenter"
  :entry "presenter.janet")

(declare-executable
  :name "presenter__sentry"
  :entry "sentry.janet")

(declare-executable
  :name "watcher"
  :entry "watcher.janet")

(defn check
  ```
  Runs the whole suite through the demiurge, which raises a fresh tree for
  every test file, and fails when any file does.

  The demiurge says how the run went over the Aether, its stdout, and
  nothing else goes there: the tests write to stderr.
  ```
  [&]
  (def proc
    (os/spawn [(dyn *executable* "janet") "demiurge.janet" "test"] :pe
              (merge (os/environ) {"CONF" "test/conf.test.jdn" :out :pipe})))
  (def result (protect (aether/read-message (proc :out))))
  (:close (proc :out))
  (os/proc-wait proc)
  (match result
    [true {:body {:failing failing}}]
    (unless (empty? failing)
      (eprint "Failing: " (string/join failing ", "))
      (os/exit 1))
    (do (eprint "The demiurge ended without a test result")
      (os/exit 1))))
