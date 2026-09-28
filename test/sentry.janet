(def tree-conf (parse (slurp "test/conf.tree.test.jdn")))
(os/setenv "CONF" "test/conf.presenter__sentry.test.jdn")
(use spork/test /environment /schema spork/http gp/net/rpc)
(import /sentry)
(import /test/support/sse)

(start-suite :docs)
(assert-docs "/sentry")
(end-suite)

(setdyn :ctx ctx)
(def tree (client ;(server/host-port (tree-conf :rpc)) :test (tree-conf :psk)))
(def door "localhost:8880")
(defn secret
  "Offers the password `s` at the door, answering all it said back."
  [s & needles]
  (sse/until (sse/post door "/" (string `{"secret":` (json/encode s) `}`)) 0 needles))

(ev/go sentry/main)
(ev/sleep 1) # Settle the server and the registration

(start-suite :door)
(let [resp (request "GET" (string "http://" door "/"))]
  (assert (success? resp) "The door answers where the presenter would")
  (assert ((success-has? `Presenter` `id="stage"` `http://localhost:8880/content`) resp)
          "with the presenter's shell and an empty stage"))
(assert (sse/until (sse/open door "/content") 0 [`Present Star` `Sign in to present` `id="gate"`])
        "Its stage asks for the password")
(assert (secret "nope" `That was not the password` `id="gate"`)
        "A wrong password is refused, and the form stays")
(defn cookie [session] @{:headers @{"Cookie" @{"session" session}}})
(let [said (secret "testist" `Set-Cookie: session=` `Moving` `the Presenter`)
      [session] (peg/match ~(* (thru "Set-Cookie: session=") (<- (to ";"))) (or said ""))
      [flags] (peg/match ~(* (thru "Set-Cookie: session=") (<- (to "\r\n"))) (or said ""))]
  (assert said "The password opens the door, and says where it is going")
  (assert (and (string/find "Secure" flags) (string/find "HttpOnly" flags))
          "with a cookie no script can read and no plain line can carry")
  (assert ((:cap/session tree :presenter/sentry) (cookie session))
          "The tree holds the session the presenter will be asked for"))
(end-suite)
(os/exit 0)
