# Deploying to pan.earth

present-star lives on the pan.earth box (Alpine, 89.167.63.115) beside
interstudy, metabolon and pacts:

| Name | Door | Port on the box |
|---|---|---|
| `decks.pan.earth` | the lecturer: presenter, held by presenter/sentry | 7880 |
| `show.pan.earth` | the students: watcher | 7881 |
| mycelium | demiurge, tree, decker, presenter, presenter/sentry, watcher | 4843–4848 |

Everything listens on localhost; nginx is the only way in. The config with
the real secrets is `conf.show.pan.earth.jdn`, gitignored.

The box is reached through the `pe` alias of `~/.ssh/config` (pan.earth,
port 2323). The thicket is the deploy user's, like everything under `/srv`,
so it is bootstrapped and run as `deploy@pe`; nginx and certbot want root,
which `pe` has through `doas`.

## Before

1. **The box can read the repository.** The bootstrap clones `:repo`, and
   `github.com/pepe/present-star` is private while deploy has no key for
   it. Either make the repository public, or give deploy a read-only deploy
   key and set `:repo "git@github.com:pepe/present-star.git"`.
2. **DNS.** `decks.pan.earth` and `show.pan.earth` resolve to nothing yet.
   Either an A record for each, or one `*.pan.earth` record for all -- the
   box is ready for a wildcard: `00-default.conf` answers any name without
   a site of its own with 404, and refuses the TLS handshake. Names with
   records of their own, `interstudy.pan.earth` and the rest, keep them.
3. **Free ports.** Nothing may listen where present-star will:
   ```
   ssh pe "netstat -ltn | grep -E ':(484[3-8]|788[01]) '"
   ```
   must print nothing.

## 1. Bootstrap

From the development machine, on `master`:

```
CONF=conf.show.pan.earth.jdn janet demiurge.janet bootstrap
```

As deploy, under `umask 077`, it

- removes and makes again `/srv/src/present-star` and `/srv/exe/present-star`,
  and keeps `/srv/data/present-star`
- removes and clones again `/srv/src/spork`, which interstudy's bootstrap
  uses too -- it is only the clone spork is installed from, and what is
  installed stays, but the two bootstraps must not run at once
- clones the repository, builds the pinned Janet into the `prod`
  environment, and installs spork, jhydro, gp and twm there
- uploads the config as `conf.jdn`, 0600, and builds `dm` beside the releases
- starts the demiurge, which raises nothing yet

## 2. Release, then raise the peers

```
ssh deploy@pe /srv/exe/present-star/dm release
ssh deploy@pe /srv/exe/present-star/dm state
ssh deploy@pe /srv/exe/present-star/dm run-peers
```

`release` answers at once and builds the five executables in the
background; `state` says `:busy` until it has, then `:released`. The log
should then say every peer is ready and the decker built every deck:

```
ssh deploy@pe tail -n 30 /srv/data/present-star/demiurge.log
```

## 3. nginx

One file a name, as the box keeps them:
[`decks.pan.earth.conf`](deploy/nginx/decks.pan.earth.conf) and
[`show.pan.earth.conf`](deploy/nginx/show.pan.earth.conf). Each sends its
name to its door on `[::1]`, and keeps the live slide's stream unbuffered
and open for a whole lecture.

The lecturer's door is also limited. The sentry takes a POST to any path it
does not route as a sign-in, so nginx refuses every POST but `/`, where the
password is given, `/go`, the lecturer's moves, and `/note`, the lecturer's
notes, with 405. Per client, `/` takes 6 sign-ins at once and then one every
ten seconds, and `/go` and `/note` together take 20 at once and then two a
second -- a clicker's pace, and the most anybody can guess at either while
the sentry holds the door. Past any of them, nginx answers 429 and says so
in its error log. certbot leaves all of it alone, but on the box the file
is certbot's, so change it there by hand.

```
scp deploy/nginx/decks.pan.earth.conf deploy/nginx/show.pan.earth.conf pe:/tmp/
ssh pe "doas mv /tmp/decks.pan.earth.conf /tmp/show.pan.earth.conf /etc/nginx/http.d/ &&
        doas chown root:root /etc/nginx/http.d/decks.pan.earth.conf /etc/nginx/http.d/show.pan.earth.conf &&
        doas nginx -t && doas nginx -s reload"
```

## 4. Certificates

Once both names resolve, one certificate each, as the other sites have;
certbot adds the 443 listener and the redirect to each file:

```
ssh -t pe "doas certbot --nginx -d decks.pan.earth"
ssh -t pe "doas certbot --nginx -d show.pan.earth"
```

`/etc/periodic/daily/do-certbot` renews them with the rest.

The session cookie is `Secure`, so the presenter can be signed in to only
over HTTPS.

## 5. See it work

- `https://show.pan.earth` says *Waiting for the lecture*.
- `https://decks.pan.earth` asks for the password, and opens the presenter.
- *Present* a deck: the students' page follows, slide by slide.
- The stream is not buffered: `curl -N https://show.pan.earth/content`
  prints the waiting slide at once and stays open.

## 6. Surviving a reboot

[`deploy/thickets.start`](deploy/thickets.start) is the box's
`/etc/local.d/thickets.start`, run by OpenRC's `local` service at boot. It
raises every thicket on the box -- interstudy, metabolon, metabolon-staging
and present-star -- each demiurge as deploy, with umask 077, its own
environment and absolute paths, and then asks it to `run-peers`. A thicket
whose demiurge already answers is left alone, and naming thickets raises
only those:

```
ssh pe doas /etc/local.d/thickets.start present-star
```

What it did is in syslog: `doas grep ' thickets:' /var/log/messages`. A new
thicket on the box is one more line in its list. busybox `crond` on the box
knows no `@reboot`, which is why this is not a crontab.

## Day to day

- **A deck.** Commit it, push, and `dm pull`. The decker builds it within a
  second, and every open page shows the new version. No release.
- **Code.** Push, `dm pull`, `dm release`. A release restarts the peers that
  were running, which signs the lecturer out.
- **Config, or the password.** A new password is `janet bin/secrets.janet
  <password>` into `conf.show.pan.earth.jdn`. Peers compile their config in,
  so: `scp` it as `deploy@pe:/srv/src/present-star/conf.jdn` →
  `dm stop-peers` → `dm stop` → start the demiurge as `deploy/crontab` does
  → `dm release` → `dm run-peers`.
- **Stopping.** `dm stop-peers`, then `dm stop`, until nothing listens on
  4843: `netstat -ltn | grep -c ':4843 '`. Bootstrapping again does not stop
  an old demiurge, so stop first.
- **The log** is `/srv/data/present-star/demiurge.log`.
- **Sessions** live in the tree's memory: restarting the tree signs the
  lecturer out. The decks, where the stage stands and the notes are in its
  store and survive.
- **Notes** are nowhere but in the tree's store,
  `/srv/data/present-star/tree.jimage` -- not in git. Copy it off the box
  to keep them: `scp deploy@pe:/srv/data/present-star/tree.jimage .`
