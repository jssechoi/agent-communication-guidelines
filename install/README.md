# Installer

Wires the tone standard into Claude Code, Gemini CLI and Codex on one machine.

Installing a skill is not enough to make the standard always-on: skills load when their
description matches or when they are called by name. The installer therefore also writes an
always-on mandate into each agent's instruction file. Gemini and Codex have no plugin
mechanism at all, so for those two the instruction file is the only route.

## Run it

```bash
git clone https://github.com/jssechoi/agent-communication-guidelines.git
cd agent-communication-guidelines
```

Windows (PowerShell 5.1 or later):

```powershell
powershell -ExecutionPolicy Bypass -File install\install.ps1
powershell -ExecutionPolicy Bypass -File install\install.ps1 -Tools gemini,codex -DryRun
```

macOS and Linux:

```bash
install/install.sh
install/install.sh --tools gemini,codex --dry-run
```

`-DryRun` / `--dry-run` prints the planned actions and writes nothing. Start there.

Two more options:

- `-Layout skills` / `--layout skills` copies each folder under `skills/` to `~/.claude/skills/<name>`
  instead of copying the whole repository as one plugin folder. Use it when those skills already exist
  as standalone folders. A differing existing folder is moved to
  `~/.claude/backups/agent-communication-guidelines-<timestamp>/` first; it is not left under
  `skills/`, where its `SKILL.md` would load as a second copy. Identical folders are skipped.
- `-HomeDir <path>` (PowerShell only; for `install.sh` set `HOME`) installs into another home
  directory. The tests use it to install into a temporary folder.

## What it touches

| Path | Action |
| :--- | :--- |
| `~/.claude/skills/agent-communication-guidelines/` | Copy of this repository, loaded as `agent-communication-guidelines@skills-dir` (default layout) |
| `~/.claude/skills/<name>/` | One copy per skill folder (`-Layout skills`) |
| `~/.claude/CLAUDE.md` | Mandate block appended |
| `~/.gemini/skills/agent-communication-guidelines/SKILL.md` | Written from `install/gemini-skill/SKILL.md` |
| `~/.gemini/skills/agent-communication-guidelines/references/` | `guidelines.md` (copy of `skills/agent-tone/SKILL.md`), every file in `skills/agent-tone/references/`, and `style-router.md` |
| `~/.gemini/GEMINI.md` | Mandate block appended |
| `~/.codex/AGENTS.md` | Mandate block appended |

Nothing outside the home directory is modified, and no settings file is touched.

Every appended block is wrapped in markers:

```
<!-- agent-communication-guidelines:begin -->
...
<!-- agent-communication-guidelines:end -->
```

A re-run replaces what is between the markers instead of appending a second copy, so the
script is safe to run repeatedly. Existing files are copied to `<name>.bak-<timestamp>` before
the first change, and the target file's dominant line ending is preserved.

## Where the text comes from

| File | Used for |
| :--- | :--- |
| `snippets/mandate-core.md` | The rules. Shared by all three agents, so one edit covers them all |
| `snippets/head-claude.md` | Claude heading. Names the `agent-tone` and `style-router` skills |
| `snippets/head-gemini.md` | Gemini heading. Points at the skill folder |
| `snippets/head-codex.md` | Codex heading. Prints the absolute rules path, because Codex does not resolve `@path` imports in `AGENTS.md` |
| `gemini-skill/SKILL.md` | Gemini skill template. `{{MANDATE}}` is filled with `mandate-core.md` |

`{{GUIDELINES_PATH}}` in a heading is replaced with the absolute path of this clone's
`skills/agent-tone/SKILL.md`, so **moving the clone after installing breaks that pointer.**
Re-run the installer from the new location.

## What it does not do

- **It does not find a tone section you wrote by hand.** Only marked blocks are recognised.
  Remove an earlier hand-written section first, or you will keep two copies that drift apart.
- **It does not track this clone.** The copy under `~/.claude/skills/` is a copy. After
  `git pull`, run the installer again.
- **It does not remove the other layout.** With the default layout it warns when a bundled skill
  also exists as a standalone folder in `~/.claude/skills/`; with `-Layout skills` it warns when the
  plugin folder is present. Remove one side, or use `-Layout skills` from the start.

## Removing it

Delete the marker block and everything between it from `~/.claude/CLAUDE.md`,
`~/.gemini/GEMINI.md` and `~/.codex/AGENTS.md`, then delete
`~/.claude/skills/agent-communication-guidelines/` and
`~/.gemini/skills/agent-communication-guidelines/`. Timestamped backups of the original
instruction files are next to them.

## Note on the PowerShell script

`install.ps1` is ASCII-only on purpose. Windows PowerShell 5.1 reads a BOM-less `.ps1` as the
system ANSI codepage, which corrupts Korean string literals, so all Korean text lives in the
UTF-8 snippet files and is read at run time.

Dot-sourcing it (`. .\install\install.ps1`) defines the functions without installing anything.
`tests\install.Tests.ps1` uses that to test each function, and `tests\install-sh.test.mjs` runs
`install.sh` against a temporary `HOME`. Run both with
`powershell -ExecutionPolicy Bypass -File tests\run-all.ps1`.
