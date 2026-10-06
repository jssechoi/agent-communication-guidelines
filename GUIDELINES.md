# Agent Communication & Tone Guidelines

규칙 본문은 [`skills/agent-tone/SKILL.md`](skills/agent-tone/SKILL.md) 와 같은 폴더의
[`references/`](skills/agent-tone/references/) 에 있습니다. 읽는 사람과 설치된 플러그인이 같은 한 벌을
보도록 한 곳에만 두었습니다. 이 파일은 목차와 규칙 관리 절차만 담습니다.

The rules live in [`skills/agent-tone/SKILL.md`](skills/agent-tone/SKILL.md) and its `references/`
folder. This file is a table of contents plus the procedure for changing the rules.

## 무엇이 들어 있는지 (Contents)

`SKILL.md` 는 모든 산출물에 걸리는 공통 규칙이고, 스킬이 불릴 때마다 읽힙니다. `references/` 는 문서
유형별 세부 규칙이고, `SKILL.md` §2 표에 따라 해당 문서를 쓸 때만 읽힙니다.

| 파일 | 항목 | 내용 |
| :--- | :--- | :--- |
| `SKILL.md` | §1 | 페르소나. 감정 배제, 상호 동등, 근거 명시, 단일 언어, 인사말 배제 |
| | §2 | 적용 범위. 산출물별로 읽는 절과 파일, HTML·PPTX·PDF 자동 적용, `acg 규칙으로 작성해줘` |
| | §3 | 금지 표현 표(낱말당 한 행), 오탐 기준, 추상어를 고치는 방법 |
| | §4 | 문장 종결과 판단 강도. 확인한 사실과 개연, 계측하지 않은 값, 강제 어미의 예외, 제안 |
| | §5 | 형식 지정. 메일 형식(합쇼체)과 보고 형식(개조식) |
| | §6 | 민감 정보와 자격 증명. 문체가 아니라 취급 규칙 |
| | §7 | 공통 점검표 |
| `references/mail-format.md` | M1~M3 | 문의 회신 골격, 문서 어조, 내부 관리 메타데이터 배제 |
| `references/document-rules.md` | D1~D12 | 제목, 하는 일 서술, 병렬 항목, 목적 밖 서술, 시제, 문항, 정보 순서, 사실·전망·권고, 실행 조건, 비교표, 시각적 위계, 발표 자료 줄바꿈 |
| `references/report-format.md` | R1~R10 | 결론 우선, 동일 틀, 블록별 종결, `라벨: 설명`, 평가어의 근거, 기준과 조건, 범위와 제외, 용어와 기호, 장표 구성, 재현하지 않는 요소 |
| `references/korean-expression-alternatives.md` | | §3 의 문맥별 대안 |

부속 자료: `templates/`, `examples/golden_sample.md`, `examples/document_revision_ko.md`,
[한국어 참고 샘플 분석](examples/korean_reference_notes.md),
[메일 형식과 보고 형식 작성 예](examples/report_format_ko.md). 변경 이력은 [CHANGELOG.md](CHANGELOG.md).

## 다른 스킬과의 우선순위 (Precedence)

이 저장소는 어조 규칙 외에 산문·프런트엔드 스킬 다섯 벌을 함께 담고 있습니다. 무엇을 먼저
적용하는지는 [`skills/style-router/SKILL.md`](skills/style-router/SKILL.md) 가 정합니다.

## 규칙 관리 (Maintaining the rules)

규칙은 이 저장소에서만 고칩니다. 설치된 스킬 사본과 `CLAUDE.md`·`GEMINI.md`·`AGENTS.md` 의 블록은
`install/install.ps1`·`install.sh` 가 다시 만듭니다. 사본을 손으로 고치면 다음 설치 때 덮입니다.

1. **자리를 고릅니다.** 모든 산출물에 걸리는 규칙은 `SKILL.md`, 문서 유형별 규칙은 해당 `references/`
   파일입니다. 금지 표현은 §3 표에 낱말당 한 행으로 넣고, 같은 낱말의 행이 있으면 그 행을 고칩니다.
2. **먼저 합칠 곳을 찾습니다.** 같은 뜻의 규칙이 다른 절에 있으면 새 절을 만들지 않습니다. 한 곳에 두고
   나머지는 포인터로 바꿉니다. 적용 범위는 `SKILL.md` §2 표에만 둡니다.
3. **대체 표현을 적습니다.** 대체 표현을 못 적으면 규칙이 아니라 취향이므로 넣지 않습니다. 정상 어휘로
   쓰이는 경우가 있으면 §3 오탐 기준에 한 구절로 추가합니다.
4. **분량 상한을 지킵니다.** `SKILL.md` 200줄, `references/` 파일 하나당 220줄, `mandate-core.md` 30줄입니다.
   넘으면 기존 규칙을 합치거나 지운 뒤 넣습니다. `tests/rules.test.mjs` 가 상한을 검사합니다.
5. **지우는 것도 절차입니다.** 산출물에서 더는 나오지 않는 표현, 다른 규칙에 포함된 규칙, 근거를 댈 수
   없는 규칙은 지웁니다. 지운 이유를 `CHANGELOG.md` 에 적습니다.
6. **점검표를 늘리지 않습니다.** `SKILL.md` §7 에는 모든 산출물에 공통인 항목만 둡니다. 문서 유형별 점검은
   해당 `references/` 파일 끝에 둡니다.
7. **기록하고 시험합니다.** `CHANGELOG.md` 에 날짜와 계기를 남기고
   `powershell -ExecutionPolicy Bypass -File tests\run-all.ps1` 을 통과시킨 뒤 커밋합니다. 국문 커밋
   메시지는 UTF-8 파일로 저장해 `git commit -F` 로 넘깁니다.
8. **다시 설치합니다.** 병합한 뒤 설치 스크립트를 다시 실행해 각 도구의 사본과 지시 블록을 갱신합니다.
