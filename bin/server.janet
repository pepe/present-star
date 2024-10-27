(use gp/utils gp/net)
(import /present-star :prefix "ps/")

(defn main
  "Run server on files"
  [_ title & files]
  (ev/spawn-thread
    (def sc (ev/chan))
    (server/start sc "localhost" 8000)
    (http/supervisor sc (http/on-connection (http/parser (http/static ".")))))
  (ev/spawn
    (def changed (tabseq [file :in files] file (os/stat file :modified)))
    (with [f (file/open "presentation.html" :wb)]
      (with-dyns [:out f] (ps/main "server parser" `Contemporary client side` ;files)))
    (print "File rendered")
    (forever
      (loop [[file modified] :pairs changed]
        (when (> (os/stat file :modified) modified)
          (print "File " file " changed")
          (with [f (file/open "presentation.html" :wb)]
            (with-dyns [:out f] (ps/main "server parser" title ;files)))
          (put changed file (os/stat file :modified))
          (print "File rendered")
          (break)))
      (ev/sleep 1))))
