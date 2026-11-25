# Brief: Present Star comes under tots' governance

## Telos

Agents grow Present Star under the keeper's authority, yet nothing in its repository gives them the rules, the reason it exists, or what has been decided.
Do what Metabolon did: inherit everything from tots at `governance-3`, and add only what is Present Star's own.
Judge "done" by that: an agent starting here is led to tots' rules, Present Star's Telos and its ledger.

## What to read first

1. tots' `AGENTS.md` and `ledger.md` at `governance-3`.
2. Metabolon at 3a138f7: `AGENTS.md`, `CLAUDE.md`, `ledger.md`, `briefs/README.md`, the pattern to follow.
3. Present Star's `.gitignore`, which already ignores `HANDOVER.md` and the configs.

## What is decided

- Present Star is governed under tots at `governance-3`, as Metabolon and twm are.
- The simplest solution: copy Metabolon's pattern, nothing more.

## The steps

1. Add, beside this brief:
   - `CLAUDE.md`: `@AGENTS.md`.
   - `AGENTS.md`: Metabolon's opening and "Before anything", with Present Star's name. Under "Here" only what tots does not already say: never commit `HANDOVER.md` or a `conf*.jdn` that is not the sample or a test fixture; run the tests with `JANET_PATH` set to this repository's `dev`.
   - `ledger.md`: Metabolon's header and one entry, D-001: Present Star is governed under tots at `governance-3`.
   - `briefs/README.md`: copied from Metabolon.
2. Show the four files to the keeper, then commit them on this branch.

## Rules

- Change nothing but these four files. `TELOS.md` is the keeper's to write.
- Nothing on the box; no push unless the keeper asks.
- The commit carries `Brief: briefs/2026-11-25-governance.md`, `Drafted-by:` with the model and version, and `Refs: D-001`.

## Note, 2026-11-25: the planner's review, answered by the analyst

1. `TELOS.md` does not exist yet. `AGENTS.md` names it anyway; the missing link is accepted for now. This work is done when the four files are in; the keeper's `TELOS.md` completes the Telos above, before or after the merge, as he chooses.
2. The test line reads: run the tests as `README.md` "Tests" says, with `JANET_PATH` set to this repository's `dev`. Confirm it by running the suite that way, as part of the verification.
3. "Before anything" item 2 reads: `HANDOVER.md` (not in Git, kept on the laptop): its newest sections; `DEPLOY.md` before anything on the box.
4. In `ledger.md`, the header's example link and D-001 both name `governance-3`. Nothing of Metabolon's `governance-2` or `governance-start` is copied.
