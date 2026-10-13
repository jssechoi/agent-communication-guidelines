---
name: commit-brief
description: Prepare the single HTML or Markdown brief that accompanies each GitHub commit. Use when preparing, reviewing, or amending a commit, or checking outgoing commits before a push.
---

# Commit brief

Every commit intended for GitHub includes exactly one brief describing that commit,
in the same commit as its changes. Apply this across projects, including documentation
changes. A commit message, PR description, or separately submitted file does not replace it.
Preparing a brief does not itself authorize a commit, push, or merge.

## Format

| Change | Brief |
| --- | --- |
| Complex algorithms, logic, UI, data flows, or a change that needs a diagram | HTML (`.html`) |
| Simple change explained with text, tables, and simple charts | Markdown (`.md`) |

Choose one format for the entire commit. Use HTML if any part needs a diagram or
complex visual explanation. Include that explanation in the brief; an HTML wrapper
around a text summary is not enough. Keep HTML self-contained, with inline styles
and embedded visuals such as SVG, so it opens locally without external assets.

## Content and location

Use the project's brief directory, or `docs/commit-briefs/` by default. Create a unique
descriptive filename such as `YYYYMMDD-HHMMSS-short-summary.md` (or `.html`). Preserve
earlier briefs. The containing commit establishes the association; do not try to embed
the new commit's own hash in its brief before committing.

Keep the explanation proportional to the change and use the requested language:

- Purpose and resulting behavior.
- Changes and affected files or components.
- Validation actually performed, with commands and observed results, or an explicit
  statement that validation was not run.
- Risks, limitations, or follow-up work when relevant.

Exclude credentials and secrets. Explain the change for someone who has not read
the conversation. Do not invent test results or measurements.

## Commit workflow

1. Inspect the intended changes and the staged diff. Write the brief for this commit's
   scope, not for unrelated working-tree edits or the whole branch.
2. Stage the brief together with the intended changes. Check the staged brief against
   the final staged diff; update it if the scope changes.
3. Check Markdown readability or open the HTML locally to inspect its diagrams and
   layout. Confirm the staged commit contains exactly one corresponding brief.
   Historical brief files elsewhere in the repository do not count toward this limit.
4. Commit and push only within the user's authorization. Before pushing a batch,
   check that each outgoing commit has its own brief; one brief for the batch is
   insufficient. Report missing briefs and resolve them within the permitted history
   editing scope. Do not rewrite published history without authorization.

When amending, update the commit's existing brief. If its format changes, replace
that brief instead of retaining both formats. For a squash or merge commit being
prepared, include a brief for the resulting combined change; keep historical briefs.
A correction limited to a brief can update that file without creating a recursive
brief-about-the-brief chain.
