# Deploying to pan.earth

present-star lives on the pan.earth box (Alpine, 89.167.63.115) beside
interstudy, metabolon and pacts:

| Name | Door | Where on the box |
|---|---|---|
| `decks.pospisil.work` | the lecturer: presenter, held by presenter/sentry | `/srv/run/present-star/http/presenter.sock` |
| `show.pospisil.work` | the students: watcher | `/srv/run/present-star/http/watcher.sock` |
| mycelium | demiurge, tree, decker, presenter, presenter/sentry, watcher, relay, recorder | `/srv/run/present-star/rpc/<name>.sock` |
| relay | other thickets, by their public keys | 4851, open |

Everything but the relay is a Unix socket under the config's
`:socket-root`, `/srv/run/present-star`, and nginx is the only way in: the
doors are in `http/`, whose group is nginx, the RPC sockets in `rpc/`, the
deploy user's alone. The relay listens on `0.0.0.0:4851` itself: it speaks
RPC, not HTTP, is encrypted by its own handshake, and admits only the
public keys in its `:followers`. The config with the real secrets is
`conf.show.pan.earth.jdn`, gitignored.

The box is reached through the `pe` alias of `~/.ssh/config` (pan.earth,
port 2323). The thicket is the deploy user's, like everything under `/srv`,
so it is bootstrapped and run as `deploy@pe`; nginx and certbot want root,
which `pe` has through `doas`.

## Before

1. **The box can read the repository.** The bootstrap clones `:repo`, and
   `github.com/pepe/present-star` is private while deploy has no key for
   it. Either make the repository public, or give deploy a read-only deploy
   key and set `:repo "git@github.com:pepe/present-star.git"`.
2. **DNS.** An A record for `decks.pospisil.work` and `show.pospisil.work`,
   to the box, and no AAAA, as every name of the box has none. The box
   refuses any name without a site of its own: `00-default.conf` answers
   it with 404, and refuses the TLS handshake.
3. **The socket directories.** The bootstrap makes `rpc/` itself and
   only checks `http/`, which needs root once to get nginx's group; under
   `/srv/run` both outlive a reboot:
   ```
   ssh pe "install -d -m 0711 /srv/run/present-star &&
           doas install -d -o deploy -g nginx -m 2750 /srv/run/present-star/http"
   ```
   And the relay's port must be free: `ssh pe "netstat -ltn | grep ':4851 '"`
   prints nothing.

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
[`decks.pospisil.work.conf`](deploy/nginx/decks.pospisil.work.conf) and
[`show.pospisil.work.conf`](deploy/nginx/show.pospisil.work.conf). Each
sends its name to its door's socket in `/srv/run/present-star/http`, and
keeps the live slide's stream unbuffered and open for a whole lecture.
Switch nginx to the sockets only after a release, when both exist. What
the lecturer's door is limited by is defined once, for every name that
opens it, in
[`00-present-star-limits.conf`](deploy/nginx/00-present-star-limits.conf).

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
cd deploy/nginx
scp 00-present-star-limits.conf decks.pospisil.work.conf show.pospisil.work.conf pe:/tmp/
ssh pe "cd /tmp && doas install -o root -g root -m 644 00-present-star-limits.conf \
          decks.pospisil.work.conf show.pospisil.work.conf /etc/nginx/http.d/ &&
        doas nginx -t && doas nginx -s reload"
```

### The old addresses

Until November 2026 the doors were `decks.pan.earth` and `show.pan.earth`,
and their links are still out there: in slides, in mails, on phones. Both
names keep their records and their certificates, and
[`decks.pan.earth.conf`](deploy/nginx/decks.pan.earth.conf) and
[`show.pan.earth.conf`](deploy/nginx/show.pan.earth.conf) answer them:

- anybody arriving is sent to the same path at the new name, with `308`,
  which keeps the method;
- what Datastar asks of a page already open at an old name -- a request
  with a `Datastar-Request` header or a `datastar` query, the live stream a
  student holds, the lecturer's moves -- is answered where it is, under the
  same limits. Datastar asks with `fetch`, which would follow a redirect
  itself and never move the page, so a lecture that is on is not cut.

The relay is plain TCP on `0.0.0.0:4851`, so it answers at any name of the
box; a follower that dials `pan.earth:4851` keeps working.

## 4. Certificates

Once both names resolve, one certificate each, as the other sites have;
certbot adds the 443 listener and the redirect to each file:

```
ssh -t pe "doas certbot --nginx -d decks.pospisil.work"
ssh -t pe "doas certbot --nginx -d show.pospisil.work"
```

`/etc/periodic/daily/do-certbot` renews them with the rest.

Then HTTP/2, by hand in each file on the box: `http2 on;` on the line
after certbot's `listen [::]:443 ssl; # managed by Certbot`, `nginx -t`,
and a reload. Over HTTP/1.1 a browser keeps six connections to a host, and
every open stream holds one.

The session cookie is `Secure`, so the presenter can be signed in to only
over HTTPS.

## 5. See it work

- `https://show.pospisil.work` says *Waiting for the lecture*.
- `https://decks.pospisil.work` asks for the password, and opens the presenter.
- *Present* a deck: the students' page follows, slide by slide.
- The stream is not buffered: `curl -N https://show.pospisil.work/content`
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
- **gp or twm.** The peers are built against the gp and twm installed in the
  box's `prod` environment, so a change to either is installed there before
  the release:
  ```
  ssh deploy@pe "umask 077; cd /srv/src/present-star && . ./prod/bin/activate &&
                 janet-pm install https://git.sr.ht/~pepe/gp"
  ```
- **A follower.** Another thicket may follow the lectures once its public key
  is in the relay's `:followers`, and this one follows theirs once their key
  is in the recorder's `:follows`. Both are config: see below.
- **Config, or the password.** A new password is `janet bin/secrets.janet
  <password>` into `conf.show.pan.earth.jdn`. Peers compile their config in,
  so: `scp` it as `deploy@pe:/srv/src/present-star/conf.jdn` →
  `dm stop-peers` → `dm stop` → start the demiurge as `deploy/crontab` does
  → `dm release` → `dm run-peers`.
- **Stopping.** `dm stop-peers`, then `dm stop`, until no process runs
  from `/srv/exe/present-star` or `/srv/src/present-star/prod/bin/janet`.
  Bootstrapping again does not stop an old demiurge, so stop first.
- **The log** is `/srv/data/present-star/demiurge.log`.
- **Sessions** live in the tree's memory: restarting the tree signs the
  lecturer out. The decks, where the stage stands and the notes are in its
  store and survive.
- **Notes** are nowhere but in the tree's store,
  `/srv/data/present-star/tree.jimage` -- not in git. Copy it off the box
  to keep them: `scp deploy@pe:/srv/data/present-star/tree.jimage .`
