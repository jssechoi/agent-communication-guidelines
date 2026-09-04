# Agent Communication Guidelines & Templates

This repository serves as a **Master Reference Guide** for AI agents (including Gemini, GPT, and other major LLMs) to mimic, learn, and reproduce the high-signal, professional, and consultative tone of a senior technical account team.

Whenever you work with an AI agent in a different repository or project, you can provide this repository or its markdown files as context (e.g., as part of the `GEMINI.md` or `AGENT.md` instructions) to enforce a consistent, high-quality, professional communication standard.

---

## 📂 Repository Structure

- **`GUIDELINES.md`**: The core technical and stylistic standard. Contains the "Persona", "Banned AI-isms", "Sentence Ending Patterns", and "Document Architecture".
- **`templates/`**: Actionable templates that agents can copy and fill in.
  - `templates/qa_response.md`: Structure for answering complex technical questions.
  - `templates/strategic_suggestion.md`: Layout for proposing proactive, high-value consulting insights.
- **`examples/`**: Real-world examples showcasing the rules in action.
  - `examples/golden_sample.md`: The original reference support email (Korean & English) from a premium LLM Provider to an Enterprise Client.

---

## 🚀 How to Use this Repository

To instruct any AI agent to use this standard, add the following prompt snippet to its instruction file (e.g., `GEMINI.md`, `AGENT.md`, or the system prompt):

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
```

---

## ✍️ Authors & Maintainers
- Developed & Maintained by: **jssechoi** (jane.doe@client-corp.com)
