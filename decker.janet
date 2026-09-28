(use /environment /schema)
(import twm/symbiont :as symbiont)
(import /parser)

(def- built
  ```
  The source each file was last built from, by file name.

  Kept beside the state rather than in it, like any machinery a producer
  owns. A file whose source is the one built last is not built again, so
  the tree hears only about decks that changed.
  ```
  @{})

(defn deck/id-of
  "The id of the deck `file` holds: its name without `.md`."
  [file]
  (string/slice file 0 -4))

(defn deck/title-of
  ```
  The title of the deck `file` holds: its name, with dashes and
  underscores as spaces. `CULS-Backend-2025.md` is CULS Backend 2025.
  ```
  [file]
  (->> (deck/id-of file)
       (string/replace-all "_" " ")
       (string/replace-all "-" " ")))

(defn source?
  "Whether `file` is a deck the decker builds, rather than one it `ignore`s."
  [ignore file]
  (and (string/has-suffix? ".md" file)
       (not (string/has-prefix? "." file))
       (not (index-of file ignore))))

(defn build
  ```
  Builds the deck in `file` from its `source`, answering what the tree is
  to be told: `[:save id deck]`, or `[:failed id error]` with the line the
  parser stopped at.

  A deck is stamped `:modified` with the time its file was saved, when it
  is known, so the decks being worked on can come first.
  ```
  [file source &opt modified]
  (def id (deck/id-of file))
  (match (protect (parser/parse-deck source (deck/title-of file)))
    [true deck] [:save id (if modified (put deck :modified modified) deck)]
    [false (err (dictionary? err))] [:failed id (merge {:file file} err)]
    [false err] [:failed id {:file file :message (string err)}]))

(defn- tell
  [tree [what id x]]
  (case what
    :save (:save-presentation tree id x)
    :failed (:build-failed tree id x)
    :remove (:remove-presentation tree id)))

(defn sources/scan
  ```
  Reads every deck in `dir`, answering the files whose source changed since
  it was last built, with that source and the time the file was saved, and
  the files that are gone.

  Every file is read on every scan. The decks are a few kilobytes each and
  reading them all is cheaper than being wrong about them: a modification
  time says nothing about two saves within the same second, and a watcher
  of file events sees an editor's atomic save, or a `git pull`, as a
  scatter of creations and removals that means something different on
  every system.
  ```
  [dir ignore]
  (def present @{})
  (def changed @[])
  (each file (sorted (os/dir dir))
    (def file-path (path/join dir file))
    (when (and (source? ignore file) (= :file (os/stat file-path :mode)))
      # A string, because `slurp` gives a buffer, and a buffer is equal
      # only to itself: every source would look changed on every scan.
      (when-let [[ok source] (protect (string (slurp file-path)))
                 _ ok]
        (put present file true)
        (unless (= source (built file))
          (array/push changed [file source (os/stat file-path :modified)])))))
  [changed (seq [file :keys built :unless (present file)] file)])

(defn ^sources/follow
  ```
  Keeps the tree's decks the same as the sources, for as long as the
  decker lives.

  First it forgets every deck the tree holds whose file is gone -- one
  deleted while nobody was watching, but never a recording, which has no
  file -- and then it scans every `:poll`
  seconds. A tree that cannot be told now is told on the next scan: only
  what the tree has accepted counts as built.
  ```
  []
  (make-watch
    (fn [_ state _]
      (def {:sources dir :tree tree :name name} state)
      (def ignore (get state :ignore ["README.md"]))
      (def poll (get state :poll 1))
      (producer
        (produce (log name " follows the decks in " dir))
        (def files (filter |(source? ignore $) (os/dir dir)))
        (def [_ held] (protect (:presentations tree)))
        (def held (if (dictionary? held) held {}))
        # A recording has no file, and was never the decker's to forget.
        (each id (keys held)
          (unless (or (index-of (string id ".md") files) (get-in held [id :recorded]))
            (protect (tell tree [:remove id]))))
        (forever
          (def [changed gone] (sources/scan dir ignore))
          (each [file source modified] changed
            (def result (build file source modified))
            (match (protect (tell tree result))
              [true _] (do
                         (put built file source)
                         (produce (log name " built " file
                                       (if (= :failed (first result))
                                         (. ", refused at line "
                                            (get-in result [2 :line] "?"))
                                         ""))))
              [false err] (produce (log name " could not tell the tree about "
                                        file ": " err))))
          (each file gone
            (when (first (protect (tell tree [:remove (deck/id-of file)])))
              (put built file nil)
              (produce (log name " removed " file))))
          (ev/sleep poll))))
    "follow sources"))

(define-watch Start
  "Starts RPC, announces readiness, and follows the sources."
  [&]
  [(^rpc/start [AetherReady (^sources/follow)])])

(def initial-state
  "Initial state"
  ((>update :rpc (update-rpc @{})) compile-config))

(symbiont/main initial-state Start)
