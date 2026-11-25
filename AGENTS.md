# Working rules for AI participants

Present Star is governed under tots (D-001). The rules of tots' `AGENTS.md` at the tag `governance-4` apply here:
`git -C ~/code/tots show governance-4:AGENTS.md`, or https://git.sr.ht/~pepe/tots/tree/governance-4/item/AGENTS.md.
This file adds to them and never loosens them. If the two seem to conflict, ask the keeper.
Claude Code reads this file through `CLAUDE.md`.

## Before anything

1. `TELOS.md`, then `ledger.md` here, then the tots ledger at the same tag.
2. `HANDOVER.md` (not in Git, kept on the laptop): its newest sections; `DEPLOY.md` before anything on the box.

## Here

- `HANDOVER.md` is ignored by name; never add it back, and never commit a `conf*.jdn` that is not `conf.example.jdn` or a test fixture.
- Run the tests as `README.md` "Tests" says, with `JANET_PATH` set to this repository's `dev`.
