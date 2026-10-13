# Merge master into the commit brief branch

PR #6 could not merge because `master` rewrote the README's Repository
Structure list after this branch changed the same lines. This merge commit
brings `master` into `feat/commit-brief-skill` and resolves that conflict.

## Changes

- `README.md`: kept the `master` wording for the Repository Structure list
  (per-file `agent-tone` descriptions, `CHANGELOG.md` and `tests/` entries),
  then re-applied this branch's two edits: the skill count is eight and
  `skills/commit-brief/` is listed after the bundled third-party skills.
  The "Commit briefs across projects" section merged without conflict.
- Everything else in the merge is `master` content taken as is. No other
  file overlapped.

## Validation

| Check | Observed result |
| --- | --- |
| `grep -n '^<<<<<<<\|^=======\|^>>>>>>>' README.md` | No output |
| `README.md` line endings | CRLF on every line, as before the merge |
| `node --test tests/rules.test.mjs` | 10 pass, 0 fail |
| `node --test tests/install-sh.test.mjs` | 6 pass, 0 fail |
| `tests/install.Tests.ps1` (Pester) | Not run. PowerShell is not available in this environment. |

`install/install.sh` enumerates `skills/*/`, so the `skills` layout installs
`commit-brief` without an installer change.

## Limitations

`CHANGELOG.md` came in from `master` and has no entry for the commit-brief
skill. Adding one is left to the PR author.
