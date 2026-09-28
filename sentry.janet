(use /environment /schema)
(import twm/sentry :as sentry)

(def templates
  "Sentry templates"
  {# A tab left open on a presenter that has since timed out goes on asking
   # for its streams -- of the sentry by then. With a fallback the stray
   # request is sent to the door, which offers the way back in.
   :fallback true
   :membrane
   (fn membrane []
     # The presenter's own document, with an empty stage in place of its
     # podium. The door serves the same shell the place behind it does, so
     # the handover changes what is streamed and not what is displayed.
     (<page/> "Presenter"
              [:main {:id "stage"
                      :data-init (ds/get (sentry/place/url "/content"))}]))
   :header (<page/header/> "Presenter")
   :transition/same-membrane transition/navigating
   :transition/new-membrane transition/navigating
   :transition/logout transition/leaving
   :title
   (fn title [guards]
     @[[:h1 "Present Star"]
       [:h2 "The lecturer's door. Sign in to present."]])
   :resume
   (fn resume [guards]
     @[[:h1 "Welcome back"]
       [:h2 "Your presenter is still signed in."]
       [:p [:button {:class "primary"
                     :data-on:click (ds/get (sentry/place/url "/continue"))}
            "Continue"]
        " "
        [:button {:data-on:click (ds/get (sentry/place/url "/logout"))}
         "Sign out"]]])
   :unauthorized
   (fn unauthorized [guards home]
     @[[:h1 "Not your place"]
       [:h2 "Your session does not open the presenter."]
       [:p [:a {:href home} "Go to the entrance"]]])
   :failure
   [:p {:class "error"} "That was not the password."]})

(def rpc-funcs
  "Sentry RPC functions."
  @{:refresh (refresh/following [:cap/session])
    :stop close-peers-stop})

(define-watch Start
  "Starts RPC and registers with the tree, which announces readiness."
  [&]
  [(^rpc/start [(^tree/register :tree true)])])

(sentry/main compile-config templates rpc-funcs Start)
