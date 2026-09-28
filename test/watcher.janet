(def tree-conf (parse (slurp "test/conf.tree.test.jdn")))
(os/setenv "CONF" "test/conf.watcher.test.jdn")
(use spork/test /environment /schema spork/http gp/net/rpc)
(import /watcher)
(import /test/support/sse)

(start-suite :docs)
(assert-docs "/watcher")
(end-suite)

(setdyn :ctx ctx)
(def tree (client ;(server/host-port (tree-conf :rpc)) :test (tree-conf :psk)))
(:save-presentation tree "intro"
                    @{:title "The Intro" :author "Josef" :date "2026-02-23"
                      :slides @[[:section [:h1 "One"]]
                                [:section [:h2 "Two"] [:pre [:code "(+ 1 2)"]]]
                                [:section [:h2 "Secret third"]]]})

(def {:http http} compile-config)
(defn url [path] (string "http://" http path))
(ev/go watcher/main)
(ev/sleep 1) # Settle the server and the first projection

(start-suite :http)
(let [resp (request "GET" (url "/"))]
  (assert (success? resp) "Anyone may follow")
  (assert ((success-has? `class="watching"` `/content` `Waiting for the lecture`) resp)
          "and is told to wait while nothing is on"))
(assert (success? (request "GET" (url "/slides.css"))) "The stylesheet is served")

(def live (sse/open http "/content"))
(assert (sse/until live 0 [`id="live"` `Waiting for the lecture`])
        "The live stream starts with what is on now")
(let [m (sse/mark live)]
  (:stage/move tree :stage "intro")
  (assert (sse/until live m [`class="announced"` `<h1>The Intro</h1>`])
          "A deck staged shows its title")
  (:stage/move tree :next)
  (ev/sleep 0.3)
  (assert-not (string/find "<h2>Two</h2>" (string (sse/until live m [`The Intro`])))
              "and nothing of the slides the lecturer pages through"))
(let [m (sse/mark live)]
  (:stage/move tree :previous)
  (:stage/move tree :present)
  (assert (sse/until live m [`<h1>One</h1>` `The Intro · Josef · 2026-02-23` `1 / 3`])
          "Presenting it starts the lecture on the open page"))
(let [m (sse/mark live)]
  (:stage/move tree :next)
  (assert (sse/until live m [`<h2>Two</h2>` `<pre><code>(+ 1 2)</code></pre>` `2 / 3`])
          "and so does every move, code and all"))
(assert (nil? (get-in watcher/initial-state [:view :presentations]))
        "The watcher never holds the decks")
(assert-not (string/find "Secret third" (string (sse/until live 0 [`2 / 3`])))
            "so a slide not yet shown is nowhere in what it sent")
(let [m (sse/mark live)]
  (:stage/move tree :stop)
  (assert (sse/until live m [`class="announced"` `<h1>The Intro</h1>`])
          "Stopping shows the title again"))
(let [m (sse/mark live)]
  (:stage/move tree :close)
  (assert (sse/until live m [`Waiting for the lecture`])
          "and closing sends everyone back to waiting"))
(sse/close live)
(end-suite)
(os/exit 0)
