# Plan: the presenter is only its own page

The planner's answer to `briefs/2026-11-27-own-page-only.md` (branch `edit/2026-11-27-own-page-only`, brief e8f328b). D-003; twm D-012; locker D-003.

## Context

Locker opens each door in a window of its own, and twm at `a1181a3` no longer draws a place into an Avatar's page. On that twm the presenter does not load: `presenter.janet:3` imports `twm/door` and calls `door/link`, `door/absolute`, `door/<stylesheet/>` and `door/msg/closed`. This removes everything that rendered the presenter into an Avatar's page. The window becomes what it already is to the server: the presenter's own page, signed in by a cookie. The tests show it.

## Answers to "To find out"

1. **What goes.** The brief's list is right, and nothing on it serves anything else. These also serve only the door, and go with it:
   - `(import twm/door :prefix "")` (`presenter.janet:3`). `door/base` stays in twm, but here it is called only inside `:door/address` branches.
   - `test/tree.janet:177-186`. It presents the door's session as a bearer. twm `a1181a3` reads the cookie alone (`session/presented`), so these become cookie checks.
   - The comment in `public/present-star.css:12-16` ("Through an Avatar's door…", "a door, read as the root").
   - The comment on `:origins` in `test/conf.test.jdn:83`. It becomes "An Avatar of a Locker may open the presenter in a window of its own".
   - The `:door/css` comment in `conf.example.jdn:104-106`.

   These stay. They use "door" for a listener, or for the guardian's way in, which twm keeps:
   - `sentry.janet`, `environment.janet`, `tree.janet`;
   - `/_door/open` in `deploy/nginx/00-present-star-limits.conf`;
   - `DEPLOY.md`, and `test/sentry.janet`'s `:door` suite.
2. **The window.** The session a door gave (holder "locker/pepe") is one more live token in the tree's `:cap/session`. twm's `session/check-with` admits any live token presented as the `session` cookie, whoever holds it. So:
   - the window opens `/` and `/attending`;
   - its `/go` and `/note` move the deck, through the own page's `go()`, `note()`, halves and keys, as the lecturer's sign-in does.

   `/_door/open` is twm's. It is served on the presenter's address because the presenter's space names `:origins`. When the presenter stands down, `live` writes `:transition/logout` to every stream, whoever's it is. That sends the window to the sentry, and the sentry's `<to-locker/>` sends the lecturer on to their Locker (already shown in `test/sentry.janet:27-35`). Confirmed from the code. The tests below show the rest.

   Seen, not changed: twm's `/logout` ends only the sessions the request's cookie names, then stands the presenter down. A window's "Log out" therefore stands the presenter down for the lecturer too. The lecturer then gets the sentry's "Continue". That is twm's behaviour, and outside this brief.
3. **`CHANGELOG.md`.** The 0.1.0 entry:
   - drops "; an Avatar's door shows the presenter the same." from the styling line;
   - adds: "- Where a Locker admits the lecturer, the presenter's door sends them to it instead of asking the password, and the Locker opens the presenter in a window of its own: the presenter's own page, signed in."
4. **twm in `dev`.** `dev/twm` is an older twm. Its `bundle/info.jdn` says 0.5.0, it has `door/link`, and it has no `/_door/open`. twm's tag `0.7.0` (`2c63f11`) is 41 commits before `a1181a3`, so no release carries D-012 yet. `~/code/twm` is clean at `a1181a3`, which equals `origin/master`.
   - **Install:** with `JANET_PATH` and `JANET_TREE` set to `dev`, run `janet-pm install ../twm`. If twm then asks for a newer gp than `dev` holds, install `../gp` (clean, at `f13c2a5` = `origin/master`) the same way, and report it.
   - **Before installing:** check that no dev demiurge of the keeper's is running on this `dev` (ports 7880 and 4843). If one is, ask first.
   - **`README.md`:** under "Development", after the install lines: "Present Star needs twm at `a1181a3` or later: from there a Locker opens the presenter in a window of its own." The keeper swaps in the release number when there is one.

## The change, file by file

- **`presenter.janet`**
  - Drop the `twm/door` import.
  - `go/on` and `note/on` keep only the own page's side: `{:onclick "go(…)"}` and `{(keyword "on" event) "note(…)"}`. Their docstrings lose the door.
  - `tab/address` goes. `<tabs/>` links with plain `{:href "/" …}` and `{:href "/attending" …}`, merged with `(tab …)`.
  - Delete `<door/controls/>`, `<door/stage/>` and `entering?`.
  - `live` keeps `ds/hg/patch` and `(view :transition/logout)`. Its docstring keeps "A presenter going away takes the tab back to the door".
  - `/content` becomes `(live view <podium/>)`, and `/attending/content` becomes `(live view <attended/>)`.
- **`public/door.css`**: delete.
- **`public/present-star.css`**: drop the door sentence of the header comment and the door half of the `:root` comment.
- **`conf.example.jdn`**: drop `:door/css` and its comment.
- **`test/conf.test.jdn`**: drop `:door/css` and its comment, and reword the `:origins` comment as above. Regenerate the fixtures with `janet bin/test-confs.janet`; that drops `:door/css` from `conf.presenter.test.jdn` and `conf.presenter__sentry.test.jdn`.
- **`test/presenter.janet`**: the `:door` suite is rewritten as `:window` (below). The `:http` suite gains one assertion: the tabs' links are paths.
- **`test/tree.janet:177-186`**: `bearer` becomes `cookie`. Add one assertion: a bearer of a live door token opens nothing.
- **`README.md`**: the version sentence above.
- **`CHANGELOG.md`**: as in answer 3.
- **`ledger.md`**: D-003's "Where" goes from "not begun" to `presenter.janet`.

## Tests (`test/presenter.janet`, suite `:window`)

The window's session is recorded with a 64-hex token (`/_door/open` takes only that): `(:session/new tree win :presenter/sentry {:holder "locker/pepe"})`. Each case:

- **The window opens.** A POST to `/_door/open` with `Origin: http://pepe.locker.localhost:8790` and the body `token=<win>` answers 303 to `http://localhost:8880`, with `session=<win>` in `Set-Cookie`.
- **Both tabs open.** With `Cookie: session=<win>`, `/` and `/attending` answer 200. `/` has `function go(`, `function note(` and the `keydown` listener.
- **Moves and notes work.** `sse/open http "/content" win` streams the podium. `/go` stage answers 204, and the stream shows `class="half previous"` and `onclick="go(&quot;next&quot;)"`. `/note` answers 204, and the note comes back. The lecturer's own stream (`live`, "abcd") follows the same move.
- **No door stream.** `/content?door=enter` and `/attending/content?door=enter`, with the cookie, stream `id="podium"` and contain neither `#door` nor `psGo`.
- **No door stylesheet.** `/_door.css` and `/door.css` answer 404.
- **A bearer opens nothing.** `Authorization: Bearer <win>` with no cookie gets 401 on `/` and on `/go`.
- **An ended window opens nothing more.** After `(:session/new tree "" :presenter/sentry {:holder "locker/pepe" :token win})`, the cookie gets 401 on `/go`, and the lecturer's `go` close still answers 204.
- **Tab links are paths** (`:http`): `href="/"` and `href="/attending"` appear, and no `href="http://localhost:8880/` does.

## Verification

1. Install twm `a1181a3` into `dev` (answer 4).
2. Run the whole suite as `README.md` "Tests" says: `$env:JANET_PATH="dev"; $env:CONF="test/conf.test.jdn"; janet demiurge.janet test`. Everything passes.
3. Grep the repository outside `briefs/` for `door/address`, `_bearer`, `psGo`, `door.css`, `door/css` and `#door`: no match.
4. Push nothing; nothing on the box.

## Commits (on `edit/2026-11-27-own-page-only`)

1. "Plan the presenter rendering only its own page": this plan as `briefs/2026-11-27-own-page-only.plan.md`.
2. "Render the presenter only as its own page": the code, the CSS, the confs and fixtures, the tests, and `ledger.md`.
3. "Say in the README and changelog that a Locker opens the presenter in a window": `README.md` and `CHANGELOG.md`.

Trailers on each: `Brief: briefs/2026-11-27-own-page-only.md`, `Drafted-by: Claude Opus 5.5`, `Refs: D-003`, `Refs: twm D-012`, `Refs: locker D-003`. No `Co-Authored-By` (tots `AGENTS.md`). Before the first commit, ask once for deletion rights (tots D-036).
