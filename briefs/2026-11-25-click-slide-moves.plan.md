# Plan: clicking the slide on the stage moves the deck

The planner's answer to briefs/2026-11-25-click-slide-moves.md (branch edit/2026-11-25-click-slide-moves, brief 87d0523).

## The keeper's answers to the planner's check, 2026-11-25

- Two elements, each over one half of the stage's slide, take the click. This is simpler than measuring where the click fell.
- So nothing in the stage's slide takes a click of its own: a link there does not open, and its text cannot be selected. That replaces the earlier answer that interactive elements and selections do not move the deck. The previews, the attending tab and the watcher keep their slides as they are.
- The test also shows that the attending tab's slide takes no click.

## The change

- **`presenter.janet`, `<on-stage/>`:** the one `<slide/>` it renders gets two more children after its section: `[:button (merge {:class "half previous" :aria-label "Previous" :tabindex "-1"} (go/on "previous"))]` and the same with `next`. `go/on` already chooses `go` or `psGo` for the own page or the door, so there is no new script. `tabindex -1` keeps them out of the Tab order, since the keys already move the deck. `<slide/>` and its other callers are unchanged.
- **`public/slides.css`:** `.on-stage.lectern > .slide` gets `position: relative`. `.slide > .half` is absolute, `top: 0`, `height: 100%`, `width: 50%`, transparent, with no border or padding, and `cursor: pointer`. `.previous` gets `left: 0` and `.next` gets `right: 0`. The door's styles are the presenter's, scoped, so the door follows.

## Tests: `test/presenter.janet`

- **Staging** (`:86`): the stage carries `class="half previous"` and `class="half next"`, each exactly once, so the "Next" preview carries neither.
- **Attending** (`:194`): `class="half` does not appear.
- **Door**: after the move through the door stages `intro`, the door's `/content?door=enter` carries both halves through `psGo($_bearer,`, and still no `onclick=`.

## Verification

- `JANET_PATH=dev CONF=test/conf.test.jdn janet demiurge.janet test`: the whole suite passes.
- `git diff --stat` names only `presenter.janet`, `test/presenter.janet`, `public/slides.css` and this plan.
- The keeper, in the browser, on his own page and in an Avatar's door:
  - a click on the right half moves to the next slide, and on the left half to the previous one;
  - a click on the preview or on the attending tab's slide does nothing.

Commits carry `Brief: briefs/2026-11-25-click-slide-moves.md` and `Drafted-by: Claude Opus 5.5`.
