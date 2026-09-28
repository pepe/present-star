(use /environment /schema)

(def conf
  "Navigation to initial state in config"
  ((=>symbiont/initial-state :demiurge) compile-config))

(defn main
  ```
  Asks the demiurge to do `cmd`: `state`, `run-peers`, `stop-peers`,
  `restart-peers`, `pull`, `release`, `versions` or `stop`.
  ```
  [_ cmd]
  (def client (rpc/client ;(server/host-port (conf :rpc))
                          :client (conf :psk)))
  (pp ((keyword cmd) client)))
