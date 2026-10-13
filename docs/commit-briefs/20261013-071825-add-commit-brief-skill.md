# Shared commit brief skill

Every GitHub commit needs one accompanying brief. This change packages that
workflow as a reusable skill in the existing shared skills repository.

## Changes

- Added `skills/commit-brief/SKILL.md`: HTML for complex algorithms, logic, UI,
  data flows, or diagrams; Markdown for simple text, tables, and charts.
- Defined same-commit staging, brief contents, storage, amendment handling,
  and checks for each outgoing commit in a batch.
- Updated `README.md` with skill discovery, standalone Codex installation, and
  the global instruction needed to require briefs across projects.
- Updated `.claude-plugin/plugin.json` to version `1.1.0` and described the
  added workflow.

## Validation

| Check | Observed result |
| --- | --- |
| `python3 /home/jonghwa/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/commit-brief` | `Skill is valid!` |
| Python JSON parsing, version assertion, and skill entrypoint count | `Plugin JSON valid; version 1.1.0; 8 skill entrypoints present.` |
| `git -c core.whitespace=cr-at-eol diff --check` | Exit 0, no output; existing CRLF files retain their line endings |

The skill and Markdown documentation were reviewed as text. No application code
changed. Behavioral execution by another agent was not tested.

## Adoption

Install or update the skill and add the documented global instruction on each
machine. The existing tone installer does not install the commit mandate.
This change provides agent guidance; it does not enforce checks on GitHub.
