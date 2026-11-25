# Brief: Clicking the slide on the stage moves the deck

## Telos

The lecturer stands at the projector, often with only a mouse or a touchpad at hand, and looks at the slide, not at the buttons beside it.
Clicking the slide itself should move the deck: the right side to the next slide, the left side to the previous one.
Judge "done" by that: on the stage tab, a click on the right half of the current slide moves to the next slide, and a click on the left half moves to the previous one. This holds both on the presenter's own page and in an Avatar's door. Nothing else moves differently.

## What to read first

1. The governance brief, `briefs/2026-11-25-governance.md`, and its rules (this branch starts from it).
2. `presenter.janet`:
   - `go/on` (one intent, `go` on the own page, `psGo` with the bearer in a door), `<go/>`, and `<on-stage/>`, where the current slide is `(<slide/> (slide/at deck n))` beside the controls.
   - `<keys/>` and `<door/controls/>`: the page never moves itself. It only sends intent, and the tree pushes the slide back.
3. `environment.janet`: `<slide/>`.
4. `test/presenter.janet`: how the page's markup and the `/go` moves are tested.

## What is decided

- Only the current slide on the stage tab takes the click. The "Next" preview, the notes and the attending tab do not.
- The click is one more way to send `next` or `previous`, through `go` or `psGo`. There is no new move, no change to the tree, and no change to `/go`.
- It works whether the deck is staged or presented, as the buttons do.
- The simplest form is one click attribute on the stage's slide: compare the click's x position with half the slide's width. Anything heavier needs the keeper's go.

## To find out before the plan

- Where to put the attribute: on the slide `<on-stage/>` renders, without changing `<slide/>`'s other callers, and without breaking the `lectern` layout.
- Whether a click on a link inside a slide, or the end of a text selection, should still move the deck. The analyst proposes that neither does.

## The steps

1. Plan, and show the plan to the keeper.
2. Carry it out on this branch: `presenter.janet`, and a test in `test/presenter.janet` showing that the stage's slide carries the click and the preview does not. The whole suite passes, run as `README.md` "Tests" says.
3. The keeper tries it in the browser, then merges.

## Rules

- Change only `presenter.janet` and `test/presenter.janet`, plus `public/slides.css` if a pointer cursor is wanted.
- Never change business code to make a test pass.
- Nothing on the box; no push unless the keeper asks.
- Commits carry `Brief: briefs/2026-11-25-click-slide-moves.md` and `Drafted-by:` with the model and version.
