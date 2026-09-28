(use /environment /schema twm/demiurge spork/sh)

(setdyn *rpc-defines* [:view])

(define-effect Bootstrap
  ```
  Event that bootstraps the remote site.

  Every remote step runs under umask 077, and so does the demiurge the last
  one starts, so what the bootstrap creates and what the thicket later
  writes is the deploy user's alone: the checkout with its configuration,
  the releases, the store and the log. nginx only proxies to the thicket's
  ports.
  ```
  [_ {:host host :env env :repo repo :janet-source janet-source
      :build-path bp :data-path dp :release-path rp} _]
  (let [rbp (path/posix/join "/" ;(butlast (path/parts bp)))
        sbp (path/posix/join rbp "spork")
        conf (jdn/render compile-config)
        conf-path (path/posix/join bp "conf.jdn")
        activate [". ./prod/bin/activate"]]
    (eprin "------------ Ensure paths")
    (exec
      ;(ssh-cmds host
                 [:umask "077"]
                 [:rm "-rf" bp] [:rm "-rf" rp] [:rm "-rf" sbp]
                 [:mkdir :-p rbp] [:mkdir :-p rp] [:mkdir :-p dp]
                 [:chmod "700" rp dp]))
    (eprint " done")
    (eprint "------------ Ensure repositories")
    (exec
      ;(ssh-cmds host
                 [:umask "077"]
                 [:git :clone "--depth=1" repo bp]
                 [:git :clone "--depth=1"
                  "https://github.com/janet-lang/spork" sbp]))
    (eprint "------------ Ensure environment")
    (exec
      ;(ssh-cmds host
                 [:umask "077"]
                 [:cd bp]
                 ["/usr/local/lib/janet/bin/janet-pm" :full-env env]
                 ;(if janet-source (janet/build-steps janet-source bp env) [])
                 activate
                 [:janet "--install" sbp]
                 [:janet-pm :install "jhydro"]
                 [:janet-pm :install "https://git.sr.ht/~pepe/gp"]
                 [:janet-pm :install "https://git.sr.ht/~pepe/twm"]))
    (eprin "------------ Upload configuration")
    # Copied as a file rather than written through a heredoc inside a shell
    # command: the configuration carries a password hash full of
    # backslashes, and a command string loses one somewhere on its way to
    # the remote shell -- a secret two bytes too long is a door nobody can
    # open.
    (def tmp "conf.upload.tmp.jdn")
    (spit tmp conf)
    (defer (os/rm tmp)
      (exec "scp" tmp (string host ":" conf-path)))
    (exec ;(ssh-cmds host [:chmod "600" conf-path]))
    (eprint " done")
    (eprint "------------ Quickbin dm")
    (exec ;(ssh-cmds host
                     [:umask "077"] [:cd bp] activate
                     [:janet-pm :quickbin "bin/dm.janet" "dm"]
                     [:mv "dm" rp]))
    (eprint "------------ Run demiurge")
    (exec ;(ssh-cmds host
                     [:umask "077"] [:cd bp] activate
                     [:nohup (path/posix/join bp env "bin" "janet")
                      (path/posix/join bp "/demiurge.janet") ">>"
                      (path/posix/join dp "/demiurge.log")
                      "2>&1 &"]))))

(define-effect EnsureData
  "Makes the data path, which a fresh checkout does not have yet."
  [_ {:data-path dp} _]
  (unless (os/stat dp) (os/mkdir dp)))

(def initial-state
  "Navigation to initial state in config"
  ((=<> (=>symbiont/initial-state :demiurge)
        (>update :rpc (update-rpc rpc-funcs))
        (>put :config compile-config)
        (>put :nav/symbiont =>symbiont/initial-state)) compile-config))

(demiurge/main initial-state
  ["bootstrap"] [(^bootstrap-arg mode) Bootstrap]
  ["test" file & files] [EnsureData PrepareView (apply ^test/names file files)]
  ["test"] [EnsureData PrepareView (^test :full ;(sorted (os/dir "test")))]
  [HeartCheck EnsureData PrepareView RPC Ready])
