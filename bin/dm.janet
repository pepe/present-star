(use /environment)
(import twm/schema :only [load-config] :prefix "")

(def conf/file
  ```
  The configuration `dm` reads when it runs: CONF, or `conf.jdn`, where it
  was built, by its absolute path. Only the path is compiled in, never the
  configuration, so a rotated psk or a moved door reaches `dm` without a
  rebuild.
  ```
  (let [file (os/getenv "CONF" "conf.jdn")
        [found real] (protect (os/realpath file))]
    (if found real file)))

(defn conf
  "The demiurge's door and key, from CONF or `conf/file`, read when `dm` runs."
  []
  ((=>symbiont/initial-state :demiurge)
    (load-config (os/getenv "CONF" conf/file))))

(defn main
  ```
  Asks the demiurge to do `cmd`: `state`, `run-peers`, `stop-peers`,
  `restart-peers`, `pull`, `release`, `versions` or `stop`.
  ```
  [_ cmd]
  (def {:rpc rpc :psk psk} (conf))
  (def client (rpc/client ;(server/host-port rpc) :client psk))
  (pp ((keyword cmd) client)))
