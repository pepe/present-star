(use /environment /schema)
(import twm/sentry :as sentry)

(def- locker
  ```
  Where a person comes in from: the Avatar the entrance names first among
  its `:origins`, or nil where none may come -- in development -- and the
  entrance asks the password itself.
  ```
  (some |(if ($ :entrance) (first (get $ :origins [])))
        (values (get compile-config :spaces {}))))

(def- <to-locker/>
  ```
  What the entrance offers instead of the password where a Locker admits
  people: the way to it, taken at once. Signing out of the presenter ends
  its session and nothing of the Locker's, so the lecturer lands among
  their doors. Replaced rather than followed, so Back does not return to a
  door that would only send them on again.
  ```
  [:p [:a {:href locker :data-init "window.location.replace(el.href)"}
       "Go to your Locker"]])

(def templates
  "Sentry templates"
  {:form (if locker <to-locker/>)
   # A tab left open on a presenter that has since timed out goes on asking
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
       [:h2 (if locker
              "The lecturer's door. Enter it from your Locker."
              "The lecturer's door. Sign in to present.")]])
   :resume
   (fn resume [guards]
     @[[:h1 "Welcome back"]
       [:h2 "Your presenter is still signed in."]
       [:p [:button {:class "btn btn-primary"
                     :data-on:click (ds/get (sentry/place/url "/continue"))}
            "Continue"]
        " "
        [:button {:class "btn" :data-on:click (ds/get (sentry/place/url "/logout"))}
         "Sign out"]]])
   :unauthorized
   (fn unauthorized [guards home]
     @[[:h1 "Not your place"]
       [:h2 "Your session does not open the presenter."]
       [:p [:a {:href home} "Go to the entrance"]]])
   :failure
   [:p {:class "alert alert-error" :role "alert"} "That was not the password."]})

(def rpc-funcs
  "Sentry RPC functions."
  @{:refresh (refresh/following [:cap/session])
    :stop close-peers-stop})

(define-watch Start
  "Starts RPC and registers with the tree, which announces readiness."
  [&]
  [(^rpc/start [(^tree/register :tree true)])])

(sentry/main compile-config templates rpc-funcs Start)
