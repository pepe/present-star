# Present Star

Decks written in Markdown, presented at a URL, followed live.

- The lecturer writes decks as Markdown files.
- The lecturer presents them at a URL, behind a password, with notes on
  the slides that nobody else sees.
- The students follow at another URL: every slide the lecturer moves to
  appears on their screens, and nothing they have not been shown yet.

It is a Thicket grown with [TWM](https://git.sr.ht/~pepe/twm) on
[gp](https://git.sr.ht/~pepe/gp).

## The thicket

| Symbiont | Role | What it does |
|---|---|---|
| `demiurge` | lifecycle | raises, watches and restarts the others |
| `tree` | canonical truth | keeps the decks, their build errors, the stage -- which deck, which slide, presented or not -- and the notes |
| `decker` | builder, mycelium only | reads the decks' Markdown, parses it, and proposes the decks to the tree |
| `presenter` | avatar, guarded | the lecturer's page: the slide, its note, the next one, the decks; moves the stage |
| `presenter/sentry` | sentry | holds the presenter's door until the password is given |
| `watcher` | cosymbiont | the students' page: the live slide, and only that |
| `relay` | cosymbiont, membrane RPC | the live slide for other thickets, to the public keys it was given |
| `recorder` | mycelium only | follows other thickets' relays, and records what they show into this tree |

The presenter never moves the stage itself. It asks the tree, and the tree
tells every page what the stage is now.

## Decks

A deck is a Markdown file in the decker's `:sources`, `presentations/` in
development. Its title is its file name, dashes and underscores as spaces:
`CULS-Backend-2025.md` is *CULS Backend 2025*.

A deck is one or more sections. Each section opens with a frontmatter, and
the sections are parted by `===`:

```
author: Josef Pospíšil
date: 2024-02-26
title: The Intro
---
## First slide
* a bullet
---
## Second slide
===
---
author: Josef Pospíšil
date: 2024-02-27
title: Tools
---
## First slide of the second section
```

Between the `---` lines of a section go its slides:

- headings `#`, `##`, `###`
- bullets with `*` or `-`, numbered lists `1.`
- paragraphs, `> quotes`, `![alt](src)` images
- `` `code` ``, `**bold**`, `*emphasis*`, `[links](https://janet-lang.org)`
- fenced code blocks with their language, `` ```janet ``; a `---` or `===`
  inside one is code

A deck that cannot be read is refused with the line it broke at, shown on
the presenter's page. The deck built before it stays, on the stage too.

## Presenting

A deck is staged first. The students see only its title, the other decks
are put away, and the lecturer pages through it freely -- arrow keys,
PageUp and PageDown, a clicker, or the buttons -- writing notes on the
slides. *Present* shows the students the slide the lecturer is on, and every
move after it. *Stop* hides the slides again, the deck still staged, and
*Close* takes it off the stage.

A note belongs to its slide, and is saved when the lecturer leaves it. The
notes are kept by the tree, not in the Markdown, so nothing but the
presenter ever holds them. When a deck changes, each note goes with its
slide: a slide moved takes its note along, and so does one edited in place.
A note whose slide was taken out is kept aside, shown with the slide it was
written on, to be put on another slide or forgotten.

## Following another thicket

A lecturer with a thicket of their own can attend a lecture given from
another one, and take notes on it. Every slide shown there is recorded into
their own tree as it is shown, and the notes are written on the recording.

- The other thicket's **relay** hands out the live slide, as the students'
  page does, over an encrypted RPC on a port of its own. It admits only the
  thickets whose public keys it was given, as `:followers`.
- This thicket's **recorder** follows the relays given in `:follows`, each
  known by its public key, and records every slide they show. One deck is
  one recording, lecture after lecture, its slides in the lecturer's order.
- The presenter shows what is being attended, on its slide, with a note to
  write. A recording is a deck like any other: it can be staged, paged
  through with its notes, and presented.

Each thicket has one `:identity`, a keypair from `janet bin/secrets.janet`.
Following is swapping keys: give the other lecturer your `:public`, put it
in their relay's `:followers`, and put theirs in your recorder's `:follows`:

```
:relay {:identity {:public "…" :secret "…"}
        :followers {"colleague" "<their public key>"}}
:recorder {:identity {:public "…" :secret "…"}
           :follows {"their.host" {:rpc "their.host:4851" :key "<their public key>"}}}
```

No secret ever travels: a public key lets nobody in who does not hold its
secret. A recorded slide is kept only as far as it is plain text, headings,
lists, code, and links and images on the web: it is shown in the lecturer's
own signed-in page, so nothing from elsewhere may run there.

## Development

The project keeps its dependencies in a janet-pm environment of its own:

```
janet-pm env dev
. dev/bin/activate
janet --install ../spork     # or wherever spork, jhydro, gp and twm are
janet-pm install jhydro
janet-pm install https://git.sr.ht/~pepe/gp
janet-pm install https://git.sr.ht/~pepe/twm
```

Copy `conf.example.jdn` to `conf.jdn`, point its addresses at `localhost`,
set `:builder false` and `:sources "presentations"`, and give it secrets of
its own (below). Then

```
janet bin/demiurge.janet
```

raises the thicket and restarts it whenever a Janet source changes. The
lecturer's door is on port 7880, the students' on 7881. Decks and the
stylesheet are no sources: the decker rebuilds a deck the moment it is
saved, and pages that show it update themselves.

`janet bin/dm.janet state` asks the demiurge how it is; `run-peers`,
`stop-peers`, `restart-peers` and `stop` do what they say.

### Secrets

```
janet bin/secrets.janet <password>
```

prints a fresh mycelium `:psk`, and the sentry's `:key` and `:secret` for
that password. The password itself is written nowhere.

## Tests

```
CONF=test/conf.test.jdn janet demiurge.janet test              # all
CONF=test/conf.test.jdn janet demiurge.janet test presenter    # one file
```

The demiurge raises a fresh tree for every test file, so a test file
cannot run on its own. The test password is `testist`. After changing
`test/conf.test.jdn`, regenerate the per-symbiont fixtures with
`janet bin/test-confs.janet`.

## pan.earth

The lecturer's door is `decks.pan.earth`, the students' `show.pan.earth`.
Their configuration is `conf.show.pan.earth.jdn`, gitignored, with the real
secrets. The decks travel with the code: on the box the decker reads
`presentations/` of the checkout, so a pushed deck is published by `dm pull`.

[DEPLOY.md](DEPLOY.md) takes the box from nothing to a lecture: the
bootstrap, the release, nginx ([deploy/nginx](deploy/nginx)), certbot, and
what to do day to day.

## On Windows

A connection to a closed local port blocks Janet's whole event loop for
about two seconds on Windows. It shows only when a peer dies without saying
goodbye, and never on the Linux box.
