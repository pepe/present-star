# Brief: The presenter is only its own page

## Telos

Since November the presenter also renders itself for an Avatar's door: a second stage for `/content?door=enter` and `/attending/content?door=enter`, controls of its own for a page that is not its own (`psGo`, `psNote`, `psKey`, carrying the bearer), tabs and slides rewritten to name the presenter in full, a closed door where its own page would go back to the sentry, and `public/door.css` with its sheets scoped to `#door`.
After prolonged use the keeper decided against drawing a place into an Avatar's page (locker D-003). Locker now opens each door in a window of its own (Locker `9b6f36e`), and twm draws nothing into another page any more (twm D-012, merged at `a1181a3`): `door/link`, `door/absolute`, `door/<stylesheet/>`, `door/msg/closed`, `door/css` and the `:door/address` they turn on are gone, so the presenter does not even load on that twm.
Judge "done" by that: the presenter renders one page, its own, whoever opened it; a window Locker opens is that page, signed in, its slides moved by clicks, keys and notes as on the presenter's own page; Present Star runs on twm at `a1181a3`, or the release the keeper makes of it, all shown by tests.

## What to read first

1. `AGENTS.md`, `TELOS.md` and `ledger.md` here, and through them tots' rules at `governance-4`. `HANDOVER.md`: its newest sections.
2. twm at `a1181a3`: `ledger.md` D-012, `briefs/2026-11-26-places-open-in-their-own-window.md`, `README.md` "Entering from another Thicket", and `door/open-route` in `twm/app.janet` (a window's post, taken only from an `Origin` among the place's `:origins`).
3. Locker at `9b6f36e`: `ledger.md` D-003 to D-006 and `README.md`, for how a window is opened and how long its session lives.
4. `briefs/2026-11-25-click-slide-moves.md`, its plan, and `52f8467`: the clicks on the stage's slide, built for both pages; only the own page's side stays.
5. Here: `presenter.janet` (`go/on`, `note/on`, `tab/address`, `<tabs/>`, `<door/controls/>`, `<door/stage/>`, `live`, `entering?`, `/content`, `/attending/content`, and every other reader of `:door/address`); `sentry.janet` (`locker` and `<to-locker/>`, which stay); `public/door.css`; `:door/css` and its comments in `conf.example.jdn` and the test confs; `test/presenter.janet`, the `:door` suite; `CHANGELOG.md`, `README.md`.

## What is decided

- Present Star follows locker D-003 and twm D-012 (recorded here as D-003): the presenter renders only its own page.
- `:origins` stays on the presenter and its sentry. tots writes it from the crossings; with twm at `a1181a3` it says only whom a place lets open it in a window, and the sentry still reads it to send the lecturer to their Locker instead of asking the password.
- Only the drawn door goes. "Door" also names an HTTP listener here (the lecturer's, the students', the relay's): those, the relay and the watcher are not touched.
- What tots writes into the box's confs (`:door/css` among it) and the box's move onto the new twm are tots' work, on its own brief, after this one. Nothing here goes onto the box.

## To find out before the plan

These are the analyst's proposals for the planner to check against the code and bring back, not decisions already accepted.

- **What goes.** The proposal: every `(dyn :door/address)` branch, each keeping the own page's side (`go(...)`, `note(...)`, the path alone in `tab/address`); `entering?` and the stages answered for it; `<door/controls/>` and `<door/stage/>`; `door/absolute` and `door/msg/closed` in `live`; `door/link` replaced by the plain link it was on the own page; `public/door.css`, `:door/css` and their comments in `conf.example.jdn` and the test confs. Bring back anything else that served only the door, and anything on this list that serves something else.
- **The window.** A window Locker opens holds a session the door gave (holder "locker/pepe") as the presenter's own cookie. Confirm that it opens the stage and the attending tab, that its clicks, keys and notes move the deck as the lecturer's own sign-in does, and that a presenter standing down sends it to the sentry, which sends the lecturer on to their Locker.
- **`CHANGELOG.md`.** Its unreleased entry says an Avatar's door shows the presenter. Propose what it says now.
- **Twm in `dev`.** `dev` still carries a twm with `door/link`. How the planner puts twm at `a1181a3` into `dev`, and what `README.md` says of the version.

## The steps

1. Plan from the sources above: the answers to the questions, the changes file by file, `README.md`, `CHANGELOG.md` and `conf.example.jdn` with them, and the tests that show each case (both tabs answer their own stream whatever `door=` the query says, and `/_door.css` is not served; the tabs' links are paths; a session a door gave, presented as the cookie, opens both tabs and moves the deck by `/go` and `/note`; the slide's halves and the keys work as on the own page; a bearer opens nothing; a door session ended opens nothing more, and the lecturer's own goes on). Show the plan to the keeper before writing code.
2. Carry it out on `edit/2026-11-27-own-page-only`. The whole suite passes, run as `README.md` "Tests" says, with `JANET_PATH` set to this repository's `dev`.
3. Report the result and any deviation. The analyst checks it against the Telos; the keeper merges.
4. Then the analyst writes tots' brief: its own leftovers, the box's confs, and the box's move to the new twm.

## Rules

- Plan first and show the plan to the keeper before writing code.
- Change only Present Star's own files. Not twm, not Locker, not tots; not the relay, the watcher or the recorder.
- Nothing on the box; no push unless the keeper asks.
- Commits carry `Brief: briefs/2026-11-27-own-page-only.md`, `Drafted-by:` with the model and version, and `Refs: D-003`, with `twm D-012` or `locker D-003` where they are the reason.
