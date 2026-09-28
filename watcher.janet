(use /environment /schema)
(import twm/symbiont :as symbiont)

(setdyn *handler-defines* [:view])

(def followed
  ```
  What the watcher follows of the tree: the live slide, and nothing else.

  A watcher is a cosymbiont. Whoever opens it follows the lecture, and it
  is built so that it cannot show them more: it never asks for the decks,
  so the slides still to come are not anywhere it could leak them from.
  ```
  [:live])

(defn <live/>
  ```
  The live slide as the audience sees it, the title of a deck staged but
  not presented yet, or word that nothing is on.
  ```
  []
  (define :view)
  (if-let [live (view :live)]
    (if (live :content)
      [:div {:id "live"}
       (<slide/> (live :content))
       [:div {:class "live-line"}
        (<deck/line/> live)
        [:span (inc (live :slide)) " / " (live :count)]]]
      [:div {:id "live" :class "announced"}
       (<slide/> [:section {:class "title-card"} [:h1 (live :title)]])])
    [:div {:id "live" :class "waiting"}
     [:h1 "Waiting for the lecture"]
     [:p {:class "muted"}
      "The slides appear here as soon as the lecturer starts. "
      "There is nothing to reload."]]))

(def- <full-screen/>
  "Full screen, for the projector: `f`, or the button."
  @[[:script
     (hg/raw
       ``function fullScreen() {
          if (document.fullscreenElement) document.exitFullscreen();
          else document.body.requestFullscreen();
        }
        document.addEventListener("keydown", function (e) {
          if (e.key === "f" && !e.altKey && !e.ctrlKey && !e.metaKey) fullScreen();
        });``)]])

(defh /index
  "The watcher's page."
  [page/app]
  ["Live"
   @[[:div {:class "following" :data-init (ds/get "/content")} (<live/>)]
     [:p {:class "screen-control"}
      [:button {:onclick "fullScreen()"} "Full screen"]]
     ;<full-screen/>]
   nil
   "watching"])

(defh /content
  ```
  The page's one live stream. It renders the live slide once, and again
  every time the tree says the stage moved.
  ```
  []
  (view/stream
    view followed
    (fn [] (ds/hg/patch (<live/>)))
    (fn [_] (ds/hg/patch (<live/>)))))

(define-event PrepareView
  "Initializes the view and puts it in the dyn"
  {:update
   (fn [_ state]
     (put state :view @{:name (state :name)}))
   :effect (fn [_ {:view view} _]
             (setdyn :ctx ctx)
             (setdyn :view view))})

(def routes
  "HTTP routes"
  @{"/" /index
    "/content" /content})

(def rpc-funcs
  "RPC functions"
  @{:refresh (refresh/following followed)})

(def initial-state
  "Initial state"
  ((=> (>put :routes routes)
       (>update :rpc (update-rpc rpc-funcs)))
    compile-config))

(symbiont/main initial-state (^start PrepareView followed) HTTP)
