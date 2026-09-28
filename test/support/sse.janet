# A live event stream, read as it goes. Not a test: the runner takes only
# the `.janet` files at the top of `test/`.
#
# `spork/http` stops a stream at its first message, and admin-sentry's `sse`
# reads until the far end closes -- which a live page's `/content` never
# does. This keeps the socket open and reads until what is expected arrives.

(defn open
  "Opens `path` on the `http` host as a live stream, with the `session` cookie if given."
  [http path &opt session]
  (def [host port] (string/split ":" http))
  (def conn (net/connect host port))
  (:write conn
          (string "GET " path " HTTP/1.1\r\n"
                  "Host: " http "\r\n"
                  (if session (string "Cookie: session=" session "\r\n") "")
                  "\r\n"))
  @{:conn conn :buf @""})

(defn post
  ```
  Posts `body` as JSON to `path` on the `http` host and reads what comes
  back as a stream -- a door answers a password with several messages, and
  what it says about the password is never the first of them.
  ```
  [http path body]
  (def [host port] (string/split ":" http))
  (def conn (net/connect host port))
  (:write conn
          (string "POST " path " HTTP/1.1\r\n"
                  "Host: " http "\r\n"
                  "Content-Type: application/json\r\n"
                  "Content-Length: " (length body) "\r\n"
                  "\r\n" body))
  @{:conn conn :buf @""})

(defn mark
  "Where the stream has been read up to; what `until` looks after."
  [s]
  (length (s :buf)))

(defn- found?
  "Whether `needles` appear in `text` in this order."
  [text needles]
  (var at 0)
  (var ok true)
  (each needle needles
    (if-let [i (string/find needle text at)]
      (set at (+ i (length needle)))
      (set ok false)))
  ok)

(defn until
  ```
  Reads until every one of `needles` has arrived after `from`, in this order,
  and returns what arrived after `from`; nil when it has not within
  `seconds` (default 5), or when the stream ended first.
  ```
  [s from needles &opt seconds]
  (default seconds 5)
  (def {:conn conn :buf buf} s)
  (defn now [] (string (slice buf from)))
  (def deadline (+ (os/clock) seconds))
  (var ended false)
  (while (and (not ended) (not (found? (now) needles)) (< (os/clock) deadline))
    (match (protect (:read conn 4096 buf 0.2))
      [true nil] (set ended true)
      _ nil))
  (if (found? (now) needles) (now)))

(defn ended?
  ```
  Whether the far end ends the stream within `seconds` (default 5). The
  connection is kept alive after a stream, so the end is its terminating
  chunk, or the socket closing.
  ```
  [s &opt seconds]
  (default seconds 5)
  (def {:conn conn :buf buf} s)
  (defn terminated? [] (string/has-suffix? "\r\n0\r\n\r\n" buf))
  (def deadline (+ (os/clock) seconds))
  (var ended false)
  (while (and (not ended) (not (terminated?)) (< (os/clock) deadline))
    (match (protect (:read conn 4096 buf 0.2))
      [true nil] (set ended true)
      _ nil))
  (or ended (terminated?)))

(defn close
  "Closes the stream from this end."
  [s]
  (protect (:close (s :conn))))
