---
name: voice-en
description: Write or rewrite English prose in a news-reporting or documentary voice, and strip Korean-interference translationese. Use for English articles, briefings, case studies, newsletters, talk scripts, and any English prose drafted from Korean sources or by a Korean-native writer. Also use when English prose reads translated, or when a news or documentary tone is requested.
---

# English Voice: News and Documentary

AI English announces itself through vocabulary and punctuation. English written by a Korean speaker announces itself through sentence architecture. The two problems are separate and need separate passes.

Load order and precedence:

1. `humanizer` removes AI tells (banned vocabulary, em dashes, rule of three, hedging, boldface). Always applies.
2. This skill sets the voice and removes Korean interference.
3. `newsroom-style` holds AP mechanics (numbers, dates, titles, headline case, attribution placement). **On any mechanical conflict, `newsroom-style` wins.** It is more specific.

## Workflow

1. Pick the profile: news or documentary. Default to news when the request does not say.
2. Fix tense and person before writing, then hold them. News is past tense, third person. Documentary prose is present tense, third person.
3. Rewrite by paragraph, never by sentence. A repaired clause inside an unrepaired paragraph leaves the rhythm audibly broken.
4. Read the result aloud. If you stumble or run out of breath, the sentence is wrong no matter how correct the grammar is.
5. Check every fact against the source. Nothing new: no number, name, date, quote, or causal claim that the source does not carry.

Expect the English to come out shorter than the Korean source, often by a quarter. If it did not shrink, the padding is still in there.

## Writing from Korean sources: restate, do not translate

Translationese comes from carrying Korean sentence architecture into English. It is not a word-choice problem, so post-editing cannot fix it. Change the order of the work instead.

1. **Extract.** Pull facts, numbers, quotes, and the line of argument into short English notes. Notes, not sentences. Do not compose yet.
2. **Close the Korean source.** This is the step that does the work. It cuts the path the structure travels.
3. **Write** from the notes alone, in the chosen profile, as if the story had been reported in English from the start.
4. **Audit** against the interference table below.

## Korean interference patterns (한국어 간섭 패턴)

| Korean habit | What comes out | Write instead |
|---|---|---|
| ~하기 위해 | In order to reduce cost, the team... | To cut cost, the team... |
| ~의 경우 | In the case of the pilot, adoption was slow. | Adoption was slow in the pilot. |
| ~를 통해 | Through the test, the team verified stability. | The test confirmed stability. (make the noun the subject) |
| ~에 대해 | discussed about the issue / regarding the issue | discussed the issue |
| ~로 보인다, ~로 판단된다 | It is expected that demand will rise. | Demand will rise, the ministry said. (attribute it, or assert it) |
| ~에 의해 | The report was written by the committee. | The committee wrote the report. |
| 다양한 | various stakeholders, various factors | name them, or cut the word |
| ~하고 있다 | The tool is being used widely. | The tool is widely used. |
| ~등 | servers, storage, etc. | servers and storage |
| ~할 수 있을 것이다 | will be able to reduce costs | can cut costs |
| 검토를 진행하다 (nominalization) | conducted a review of the plan | reviewed the plan |
| 또한, 아울러, 한편 | Also, ... In addition, ... Meanwhile, ... at every paragraph head | delete. Order carries the link |
| 저희는, 우리는 | We think that the approach is better. | The approach is better, and here is why. |
| topic-comment framing | As for the schedule, it was delayed. | The schedule slipped. |
| 관형절 누적 | one 40-word sentence with three relative clauses | one idea per sentence |
| 완곡·존대 | It would be appreciated if you could confirm. | Please confirm. |
| 억, 조 단위 | 30 billion won (no anchor for the reader) | 30 billion won (about $22 million) |
| 2026.08.19 | 2026.08.19 | Aug. 19, 2026 |
| 김철수 씨, 이영희 님 | Mr. Kim Chul-soo said | Kim Chul-soo said (full name first, then Kim) |

Two more that no table catches:

- **Article errors run both ways.** "The AI is changing the industry" needs no article. "Team decided" needs one. Neither is a style choice.
- **Long noun stacks** ("customer content performance analysis automation system") are grammatical Korean and unreadable English. Break them with prepositions: "a system that automates analysis of content performance."

## Profile: news

Mechanics live in `newsroom-style`. What follows is voice.

- Inverted pyramid. The most important fact goes first, and there is no summary at the end. News does not conclude.
- Lede: one sentence, 35 words or fewer, carrying who, what, when, where.
- One idea per sentence. Average around 20 words. Paragraphs run one or two sentences.
- **Attribution is `said`.** Not "stated", "noted", "expressed", "opined", "pointed out". Variety reads as amateur writing, and words like "claimed", "admitted", and "conceded" smuggle in the writer's judgment, which AP tells reporters to avoid. "Announced" is fine for an actual announcement. "Told" needs an object: "told reporters". People say words; they do not smile, chuckle, or sigh them.
- Attribution follows the quote: "We are committed to the project," Smith said.
- Name the weekday, not "yesterday": "approved Tuesday".
- No judgment adjectives, no "very" or "extremely", no exclamation points, no first person.
- Do not open a sentence with "There is" or "There are".
- Passive voice is allowed only when the actor is genuinely unknown. Otherwise it hides who did what.

## Profile: documentary prose

For reading, not for voiceover. The goal is the narration feel of a documentary carried by prose alone: briefings, case studies, essays, talk manuscripts.

- Present tense inside a scene, even for events long past. Step out to past tense when you need distance, and do it on purpose rather than by drift.
- Open on something concrete: one person, one room, one number. Widen to the argument only after the reader is standing somewhere.
- Time and place stamps move the story: "March 1997." "Three days later, the same room."
- Short declaratives and fragments carry weight, so spend them carefully. One every few paragraphs lands. One per paragraph is a tic.
- Let detail deliver the verdict. If the reader has to be told something was remarkable, the detail was too weak.
- Narrative, not enumeration. Put cause and consequence between the facts. A list of true statements is not a story.
- At most one question in a piece, used to change the breathing. Never open with a rhetorical question.
- No headers and no bullets in a short piece. Paragraph breaks are the structure.
- Cut the stock narration lines: "Little did they know", "But everything was about to change", "A moment that would change everything", "What happened next", "In a world where".

## Where the Korean rules invert (한국어 규칙과 반대인 지점)

`humanize-ko` is correct for Korean and wrong here. These are the specific reversals.

| humanize-ko | English |
|---|---|
| 전달동사를 변주한다 (밝혔다, 전했다, 지적했다) | `said` nearly every time. Variety is a defect, not craft |
| 인용 뒤에 "~고 밝혔다" | quote first, `Smith said` after |
| 어제, 지난 15일 | the weekday: "approved Tuesday" |
| 헤징을 걷어낸다 | keep "allegedly" and "reportedly". Legal necessity, not hedging |
| 주어를 생략한다 (한국어 기본값) | English needs the subject. Supply it |
| 문단 3~5문장 | one or two sentences in news copy |
| 종결어미를 변주한다 | English has no verb endings to vary. The equivalent levers are sentence length and how each sentence opens |
| "~중 하나" 를 쓰지 않는다 | same rule holds. "One of the most popular" is a tell in both languages |

## Final checks

- Is there a sentence a native editor would call translated? Rewrite the paragraph around it.
- Any sentence past 30 words carrying two ideas? Split it.
- Is every judgment either attributed or carried by a fact?
- Any word that can go without loss? Cut it.
- News: lede under 35 words, and every attribution `said`?
- Documentary: does the piece start somewhere concrete rather than with an abstraction?

## Reference

- AP Stylebook guidance on attribution: use "said", and avoid loaded verbs such as "claimed", "admitted", "conceded".
- Free public authorities for edge cases: Reuters Handbook of Journalism (handbookreuters.com), the BBC News Styleguide, and the Guardian and Observer style guide. The AP Stylebook itself is subscription only, so AP edge cases need a subscriber check.
- Companion skills: `humanizer` (AI tells), `newsroom-style` (AP mechanics, MIT, installed separately), `humanize-ko` (Korean output).
