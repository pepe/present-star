(use jhydro)

(defn main
  ```
  Prints fresh secrets for a thicket config, ready to paste.

  Always the mycelium `:psk`, and the thicket's `:identity` for the relay
  and the recorder: its `:public` key is what is given to other thickets,
  and theirs is what it is given, and the `:secret` never leaves the
  config. Given the `password` the presenter will sign in with, also the
  `:key` and `:secret` of the sentry guarding the presenter. The password
  itself is never written anywhere; the secret is its hash under the key,
  and the sentry verifies against both.
  ```
  [_ &opt password]
  (printf ":psk %j" (string (random/buf 32)))
  (def {:public-key public :secret-key secret} (kx/keygen))
  (printf ":identity {:public %j :secret %j}"
          (string (util/bin2hex public)) (string (util/bin2hex secret)))
  (when password
    (def key (pwhash/keygen))
    (printf ":key %j" (string key))
    (printf ":secret %j" (string (pwhash/create password key)))))
