(import twm/thicket :prefix "" :export true)
(import twm/navigation
        :only [=>symbiont/initial-state]
        :prefix "" :export true)

(def ctx "Jhydro context" "prsnstar")

(def datastar
  "Where Datastar is loaded from. One version for every place of the thicket."
  "https://cdn.jsdelivr.net/gh/starfederation/datastar@1.0.0-RC.7/bundles/datastar.js")

# HTTP
(defn <page/head/>
  "HTML page head"
  [title]
  [:head
   [:title title " · Present Star"]
   [:meta {:charset "utf-8"}]
   [:meta {:name "viewport" :content "width=device-width, initial-scale=1"}]
   [:link {:rel "stylesheet" :href "/slides.css"}]])

(defn <page/header/>
  "HTML page header, with the logout control when `lgt` is set"
  [title &opt lgt]
  [:header
   [:span {:class "brand"} "Present Star"]
   [:span {:class "title"} title]
   # Asked over Datastar, never navigated to: `/logout` answers with a
   # stream of the transition, and a document sent there as a document
   # renders the events as text and then has nowhere to go.
   (if lgt [:button {:data-on:click (ds/get "/logout")} "Log out"])])

(defn <page/>
  ```
  The document every place of this thicket serves, with `main` inside it.

  The sentry standing in the presenter's door renders this very shell, so
  the door looks like the place behind it and only what is streamed into
  `#stage` tells them apart.
  ```
  [title main &opt lgt class]
  (hg/html
    @[hg/doctype-html
      [:html {:lang "en"}
       (<page/head/> title)
       [:body (if class {:class class} {})
        (<page/header/> title lgt)
        main
        [:script {:type "module" :src datastar}]]]]))

(defn page/app
  "Middleware wrapping a handler's `[title content lgt class]` in the page."
  [next-middleware]
  (fn :page/app [req]
    (if-let [resp (next-middleware req)
             [title content lgt class] resp]
      # The same stage the door raises. A transition is written for
      # `#stage` whichever side of the handover asks for it.
      (membrane/resp (<page/> title [:main {:id "stage"} content] lgt class))
      (http/not-found))))

(defn <moving/>
  "What a stage says while a place is changing hands."
  [verb whither place]
  @[[:h1 verb]
    [:h2 ;(if (present? whither) [whither " "] [])
     (if place (. "the " (human place)) "the entrance")
     (hg/raw "&hellip;")]])

(defn transition/navigating
  ```
  The way into the presenter: say where we are going, then go.

  The secret goes with the gate. A signal outlives the element that
  declared it, and Datastar sends every signal it holds with every request
  it makes afterwards -- so the form is emptied rather than merely taken
  away, or the password would ride along in the next URL.
  ```
  [address &opt place]
  (string
    (ds/msg/patch-signals {:secret ""})
    (ds/msg/remove-elements "#gate")
    (ds/msg/patch-elements (hg/html (<moving/> "Moving" "to" place)) "#stage" "inner")
    (ds/msg/patch-elements
      (hg/html (<script/redirect/> address)) "body" "append")))

(defn transition/leaving
  "The way out of the presenter: the same navigation, said the other way round."
  [address &opt place]
  (string
    (ds/msg/remove-elements "#gate")
    (ds/msg/patch-elements (hg/html (<moving/> "Leaving" "" place)) "#stage" "inner")
    (ds/msg/patch-elements
      (hg/html (<script/redirect/> address)) "body" "append")))

# Slides
(defn slide/at
  "The `n`th slide of `deck`, or nil."
  [deck n]
  (if (and deck n (>= n 0)) (get-in deck [:slides n])))

(defn <slide/>
  ```
  One slide as it is shown: the deck's section in a frame that keeps the
  proportions of a projector, whatever the window.
  ```
  [section &opt class]
  [:div {:class (if class (. "slide " class) "slide")}
   (or section [:section])])

(defn section/at
  "The section of `deck` its `n`th slide belongs to, or nil."
  [deck n]
  (if (and deck n)
    (find |(and (>= n ($ :first)) (< n (+ ($ :first) ($ :count))))
          (get deck :sections []))))

(defn <deck/line/>
  ```
  What, which part, who and when, as one line. A section called what its
  deck is called is not said twice.
  ```
  [{:title title :section section :author author :date date}]
  (def part (if (not= (string/ascii-lower (or section ""))
                      (string/ascii-lower (or title "")))
              section))
  [:span {:class "deck-line"}
   (string/join (filter present? [title part author date]) " · ")])

# Events
(defn refresh/following
  ```
  RPC function refreshing, of everything the tree pushes, only what
  `followed` names.

  A symbiont's world is what it follows. The tree tells every registered
  peer about every change, and whoever needs only the live slide must not
  go and fetch the whole of every deck because a deck changed -- the
  watcher would then be holding slides nobody has been shown yet.
  ```
  [followed]
  (fnr :refresh [produce-resp ok-resp]
       (def [what] args)
       (if (index-of what followed) [(^tree/refresh-view what)] [])))

(defn ^start
  ```
  Starts a symbiont's machinery: its view, its RPC, its registration with
  the tree, and its first projection of `colls`.

  Readiness comes last, after the session capability and the projection
  are both installed. A browser handed over to the presenter waits for
  exactly this, and one let through earlier would meet a door that did not
  yet know its session.
  ```
  [prepare colls]
  (make-watch
    [prepare
     (^rpc/start
       [(^tree/register :tree false
                        (projection/^refresh colls
                                             (projection/^ready)
                                             AetherReady))])]
    "start"))

# Utils
(setdyn :ctx ctx)
