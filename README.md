# Present Star

Decks written in Markdown, presented at a URL, followed live.

- The lecturer writes decks as Markdown files.
- The lecturer presents them at a URL, behind a password.
- The students follow at another URL: every slide the lecturer moves to
  appears on their screens, and nothing they have not been shown yet.

It is a Thicket grown with [TWM](https://git.sr.ht/~pepe/twm) on
[gp](https://git.sr.ht/~pepe/gp).

## The thicket

| Symbiont | Role | What it does |
|---|---|---|
| `demiurge` | lifecycle | raises, watches and restarts the others |
| `tree` | canonical truth | keeps the decks, their build errors and the stage: which deck, which slide |
| `decker` | builder, mycelium only | reads the decks' Markdown, parses it, and proposes the decks to the tree |
| `presenter` | avatar, guarded | the lecturer's page: the slide, the next one, the decks; moves the stage |
| `presenter/sentry` | sentry | holds the presenter's door until the password is given |
| `watcher` | cosymbiont | the students' page: the live slide, and only that |

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
secrets. Bootstrap the box with

```
CONF=conf.show.pan.earth.jdn janet demiurge.janet bootstrap
```

and raise the peers with `dm run-peers` there. nginx sends each name to its
door, and must not buffer the event streams:

```
server {
  server_name decks.pan.earth;
  location / {
    proxy_pass http://localhost:7880;
    proxy_http_version 1.1;
    proxy_buffering off;
    proxy_read_timeout 1h;
  }
}
server {
  server_name show.pan.earth;
  location / {
    proxy_pass http://localhost:7881;
    proxy_http_version 1.1;
    proxy_buffering off;
    proxy_read_timeout 1h;
  }
}
```

The decks on the box live in `/srv/data/present-star/decks`. A checkout of
the course repository works well there: `git pull`, and the decker builds
whatever changed.

## On Windows

A connection to a closed local port blocks Janet's whole event loop for
about two seconds on Windows. It shows only when a peer dies without saying
goodbye, and never on the Linux box.
