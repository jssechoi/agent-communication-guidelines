# Agent Communication Guidelines & Templates

This repository serves as a **Master Reference Guide** for AI agents (including Gemini, GPT, and other major LLMs) to mimic, learn, and reproduce the high-signal, professional, and consultative tone of a senior technical account team.

Whenever you work with an AI agent in a different repository or project, you can provide this repository or its markdown files as context (e.g., as part of the `GEMINI.md` or `AGENT.md` instructions) to enforce a consistent, high-quality, professional communication standard.

---

## Repository Structure

- **`skills/`**: The installable payload. Seven skills, each a `SKILL.md`.
  - `skills/agent-tone/`: **The standard itself.** Persona, banned AI-isms, restricted metaphors, banned translationese, sentence-ending patterns, document layout, self-checklist, and the document-artifact rules (§6) for forms and reports.
  - `skills/style-router/`: **Read this first.** Which skill applies to which deliverable, what wins on conflict, where Korean and English rules invert, and how to make the standard always-on.
  - `skills/humanize-ko/`, `skills/voice-en/`: Korean and English prose rules. Own work, same license as this repository.
  - `skills/humanizer/`, `skills/newsroom-style/`, `skills/design-taste-frontend/`: bundled third-party skills, each with its own `LICENSE` and `SOURCE.md`. See `NOTICE`.
- **`GUIDELINES.md`**: Pointer to `skills/agent-tone/SKILL.md` plus a section index. The rules are kept in one file only.
- **`templates/`**: Actionable templates that agents can copy and fill in.
  - `templates/qa_response.md`: Structure for answering complex technical questions.
  - `templates/strategic_suggestion.md`: Layout for proposing proactive, high-value consulting insights.
- **`examples/`**: Real-world examples showcasing the rules in action.
  - `examples/golden_sample.md`: Reference support email from a premium LLM provider to an enterprise client. Predates the §4 single-language rule, so its greeting and paired English section are **not** to be imitated.
  - `examples/document_revision_ko.md`: A human-edited Korean submission document, paired before/after. Source evidence for §2.1, §2.2 and §6.
- **`.claude-plugin/`**: Plugin and marketplace manifests for Claude Code.

---

## Install as a Claude Code plugin

```bash
claude plugin marketplace add jssechoi/agent-communication-guidelines
claude plugin install agent-communication-guidelines@jssechoi-skills
```

Skills load on the next session. `claude plugin details agent-communication-guidelines` reports the projected token cost.

**Installing is not enough to make the standard always-on.** Skills load when their description matches or when they are called by name. Tone has to apply to every deliverable, so add the mandate below to your instruction file. `skills/style-router/SKILL.md` §4 has the same snippet.

`impeccable` is referenced by the router but **not bundled**: its reference material and scripts run to about 3.2 MB across 107 JavaScript modules. Install it from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) if you want it.

### If marketplaces are blocked by policy

Managed installs can disable external marketplaces. The symptom is:

```
✘ Failed to add marketplace: 'github:jssechoi/agent-communication-guidelines' (github.com)
  is blocked by enterprise policy. No external marketplaces are allowed.
```

That is a client-side allowlist (`strictKnownMarketplaces` in org-managed settings), not a problem with this repository. Local directory sources are refused the same way, and `claude plugin install` only reads from marketplaces, so neither is a way around it. Two routes work:

- **Drop the repository into the skills directory.** A directory under `~/.claude/skills/` that contains `.claude-plugin/plugin.json` loads on the next session as `agent-communication-guidelines@skills-dir`, with no marketplace involved.

  ```bash
  git clone https://github.com/jssechoi/agent-communication-guidelines.git \
    ~/.claude/skills/agent-communication-guidelines
  ```

  Check for name collisions first. If you already keep `humanizer`, `newsroom-style`, `humanize-ko`, `voice-en` or `design-taste-frontend` as standalone skills in `~/.claude/skills/`, remove those copies or the bundled ones will shadow them.

- **Copy only the skills you want.** Every directory under `skills/` is self-contained. `skills/agent-tone/` and `skills/style-router/` are enough for the standard on its own.

If you want the normal install path, ask your administrator to add this repository to the marketplace allowlist.

---

## Use without Claude Code

To instruct any AI agent to use this standard, add the following prompt snippet to its instruction file (e.g., `GEMINI.md`, `AGENT.md`, `CLAUDE.md`, or the system prompt):

```markdown
# Communication Style Mandate
You must strictly follow the communication style and tone defined in:
https://github.com/jssechoi/agent-communication-guidelines

Specifically, prioritize:
1. Strictly avoid formal email-style greetings ("Hello", "This is...") and go straight to the core technical message.
2. Restating the user's intent clearly before answering: "저희가 이해한 문의 의도: ..."
3. Answering with "Yes/No/Confirmed" first, followed by short, dry, factual elaboration.
4. Eliminating conversational filler and exclamation marks (Be dry and crisp).
5. Utilizing the soft-instruction ending ("~해주시면 됩니다" / "please make sure").
6. Strictly avoid bilingual parallel outputs. Write consistently in a SINGLE language as requested by the prompt (Korean only for Korean contexts, English only for English contexts).
7. For Korean forms, reports and submission documents, additionally apply GUIDELINES.md §6: noun-phrase headings, state what is done rather than what is not, split three-or-more parallel items into a list, and never include estimated or "felt" figures.
```

---

## License

This repository is licensed under the **MIT License**. See `LICENSE`.

Copyright notices for the bundled third-party skills are collected in `NOTICE`. MIT requires the notice to travel with any copy or substantial portion, so keep that file with the rest when you redistribute.

The bundled skills keep their own licenses:

| Directory | License | Copyright | Upstream |
| :--- | :--- | :--- | :--- |
| `skills/humanizer/` | MIT | 2025 Siqi Chen | [blader/humanizer](https://github.com/blader/humanizer) |
| `skills/newsroom-style/` | MIT | 2025 Joe Amditis | [jamditis/claude-skills-journalism](https://github.com/jamditis/claude-skills-journalism) |
| `skills/design-taste-frontend/` | MIT | 2026 Leonxlnx | [leonxlnx/taste-skill](https://github.com/leonxlnx/taste-skill) |

They are copies of upstream material and are not edited here. Rules this project adds go into `skills/agent-tone/` for Korean or `skills/voice-en/` for English. Each directory's `SOURCE.md` records provenance and what was not recorded at copy time.

---

## Authors & Maintainers

- Developed and maintained by **jssechoi** ([github.com/jssechoi](https://github.com/jssechoi))
