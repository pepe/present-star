(use gp/data/schema gp/data/navigation)
(import twm/schema :prefix "" :export true)

(def config/base?
  "The thicket shape as twm declares it."
  config?)

(defn deck/id?
  ```
  Whether `id` can name a deck: the file name it was built from, without
  `.md`. A separator in it would name a file somewhere else.
  ```
  [id]
  (and (string? id)
       (not (empty? id))
       (not (string/find "/" id))
       (not (string/find "\\" id))))

(defn slide?
  "Whether `slide` is one htmlgen section."
  [slide]
  (and (indexed? slide) (= :section (first slide))))

(defn part?
  "Whether `part` says where a deck's section starts and how many slides it has."
  [part]
  (and (dictionary? part)
       (nat? (get part :first))
       (nat? (get part :count))))

(defn deck?
  ```
  Whether `deck` is one the tree will keep: titled, with its slides as
  sections, and its parts, when it says them, saying where each begins.
  The decker proposes decks; this is what they are held to.
  ```
  [deck]
  (and (dictionary? deck)
       (present-string? (get deck :title))
       (indexed? (get deck :slides))
       (all slide? (deck :slides))
       (let [parts (get deck :sections)]
         (or (nil? parts) (and (indexed? parts) (all part? parts))))))

(defn build-error?
  "Whether `err` says where a deck could not be read and why."
  [err]
  (and (dictionary? err)
       (present-string? (get err :file))
       (present-string? (get err :message))
       (or (nil? (get err :line)) (number? (err :line)))))

(defn move?
  ```
  Whether `move` is one the stage knows: stage, goto, next, previous,
  present, stop, close.
  ```
  [move]
  (and (indexed? move)
       (match [(length move) ;move]
         [1 :next] true
         [1 :previous] true
         [1 :present] true
         [1 :stop] true
         [1 :close] true
         [2 :stage id] (deck/id? id)
         [3 :goto id n] (and (deck/id? id) (nat? n))
         false)))

(defn note/text?
  ```
  Whether `text` can be a note. Notes are what a lecturer glances at, and
  a book is refused.
  ```
  [text]
  (and (string? text) (<= (length text) 16384)))

(defn note/change?
  "Whether `change` is one the notes know: write, attach, drop."
  [change]
  (and (indexed? change)
       (match [(length change) ;change]
         [4 :write id n text] (and (deck/id? id) (nat? n) (note/text? text))
         [4 :attach id orphan n] (and (deck/id? id) (present-string? orphan) (nat? n))
         [3 :drop id orphan] (and (deck/id? id) (present-string? orphan))
         false)))

(def- hex/key (peg/compile ~(* (64 :h) -1)))

(defn key/hex?
  "Whether `hex` is a 32 byte key written in hex, as keys are swapped."
  [hex]
  (and (bytes? hex) (truthy? (peg/match hex/key hex))))

(defn identity?
  "Whether `identity` is a thicket's keypair, `{:public :secret}`, in hex."
  [identity]
  (and (dictionary? identity)
       (key/hex? (get identity :public))
       (key/hex? (get identity :secret))))

(defn attending?
  ```
  Whether `what` says what a lecture followed from another thicket shows:
  its title, and when a slide is on, the recording and the slide in it.
  ```
  [what]
  (and (dictionary? what)
       (present-string? (get what :title))
       (or (nil? (get what :presentation))
           (and (deck/id? (what :presentation)) (nat? (get what :slide))))))

(def- twm/keys
  "Keys twm puts into a symbiont's derived state of its own accord."
  [:name :thicket :psk :spaces :peers :entries :config :build-path
   :membrane/rpc :image :public :address])

(defn config/reserved
  ```
  Every key that may stand in a symbiont's derived state beside its peers.

  A peer's address is kept under the peer's name, in the same table as the
  symbiont's own settings, so a symbiont named like a setting overwrites
  it wherever it is a peer. Nothing raises; the setting is simply gone.
  That is why the decker is not called `builder`: the demiurge reads its
  own `:builder` to decide whether peers are built executables, and a peer
  of that name would have answered for it with an address.
  ```
  [config]
  (def reserved @{})
  (defn add [dict] (eachk k (or dict {}) (put reserved k true)))
  (add config)
  (add (config :deploy))
  (add (config :runtime))
  (each block (values (get config :symbionts {})) (add block))
  (each node (values (get-in config [:mycelium :nodes] {})) (add node))
  (each node (values (get-in config [:membrane :nodes] {})) (add node))
  (each k twm/keys (put reserved k true))
  reserved)

(defn config/guardians!
  ```
  Returns `config`, or raises naming everything in it that stops a guarded
  symbiont from being raised, reached, or handed back.

  Each of these fails in silence otherwise -- a guardian nobody dials, a
  door nobody opens, a session pushed to nobody -- so the whole thicket is
  checked as it loads. A symbiont's own derived config names no
  `:symbionts` and is left alone: its thicket was checked when the
  demiurge loaded it.
  ```
  [config]
  (when-let [symbionts (config :symbionts)]
    (def fails @[])
    (defn fail [& parts] (array/push fails (string ;parts)))
    (defn has? [xs x] (truthy? (index-of x (or xs []))))
    (def nodes (get-in config [:mycelium :nodes] {}))
    (def doors (get-in config [:membrane :nodes] {}))
    (def demiurge (get symbionts :demiurge {}))
    (def reserved (config/reserved config))
    (unless (config/base? config)
      (fail "the thicket does not have the shape twm declares"))
    (each s (sorted (keys symbionts))
      (def block (symbionts s))
      (if (reserved s)
        (fail s " is named like a setting it would overwrite"))
      (unless (nodes s)
        (fail s " has no mycelium node"))
      (when-let [g (block :guarded-by)]
        (def guardian (symbionts g))
        (cond
          (nil? guardian) (fail s " is guarded by " g ", which is no symbiont")
          (and (guardian :guards) (not= s (guardian :guards)))
          (fail g " says it guards " (guardian :guards) ", but guards " s))
        (unless (has? (get-in nodes [:demiurge :peers]) g)
          (fail g " is missing from the demiurge's :peers"))
        (each x [s g]
          (unless (has? (get-in nodes [:tree :peers]) x)
            (fail x " is missing from the tree's :peers")))
        (unless (has? (demiurge :autostart) g)
          (fail g " is missing from :autostart"))
        (if (has? (demiurge :autostart) s)
          (fail s " is in :autostart, but only its guardian may raise it"))
        (each x [s g]
          (unless (has? (demiurge :builds) x)
            (fail x " is missing from :builds")))
        (unless (get-in doors [s :entrance])
          (fail s " has no membrane node with :entrance true"))))
    (def seen @{})
    (each [layer key] [[nodes :rpc] [doors :http]]
      (each x (sorted (keys layer))
        (when-let [address (-?> (get-in layer [x key]) string)]
          (if-let [other (seen address)]
            (fail x " and " other " both listen on " address)
            (put seen address x)))))
    (unless (empty? fails)
      (error (string "Invalid thicket config:\n  " (string/join fails "\n  ")))))
  config)

(def compile-config
  "Compile time configuration"
  (config/guardians! (load-config)))
