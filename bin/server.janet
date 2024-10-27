(use gp/utils gp/net)
(import /present-star :prefix "ps/")

(setdyn :watched-extensions '(+ `janet ` `temple` `md`))
(ev/spawn-thread
  (def sc (ev/chan))
  (server/start sc "localhost" 8000)
  (http/supervisor sc (http/on-connection (http/parser (http/static ".")))))
(ev/spawn
  (var changed (os/stat "intro.md" :modified))
  (with [f (file/open "presentation.html" :wb)]
    (with-dyns [:out f] (ps/main "server parser" `Contemporary client side` `intro.md`)))
  (forever
    (def last-changed (os/stat "intro.md" :modified))
    (when (> last-changed changed)
      (with [f (file/open "presentation.html" :wb)]
        (with-dyns [:out f] (ps/main "server parser" `Contemporary client side` `intro.md`)))
      (set changed last-changed)
      (print "File refreshed"))
    (ev/sleep 1)))
