---
name: style-router
description: 이 플러그인의 산문·프런트엔드 스킬이 겹칠 때 무엇을 먼저 적용할지 정한다. agent-tone, humanizer, humanize-ko, voice-en, newsroom-style, design-taste-frontend 의 적용 순서, 산출물 계열별로 함께 거는 스킬, 국문과 영문 규칙이 반대인 지점, 항상 적용을 강제하는 방법. 글이나 화면을 쓰거나 고치기 전에 먼저 읽는다. Routing and precedence for the writing and design skills bundled in this plugin.
---

# Style router

이 플러그인에는 규칙이 여섯 벌 들어 있고, 일부는 같은 문장을 서로 다르게 고치라고 합니다. 순서를
정하지 않으면 마지막에 실행된 규칙이 이깁니다. 아래가 그 순서입니다.

## 1. 적용 순서 (Precedence)

0. **`agent-tone` §6 민감 정보와 자격 증명이 다른 모든 항목보다 우선합니다.** 문체 규칙이 아니라 취급
   규칙이라 산문·코드·데이터 표·로그를 가리지 않고 걸립니다. 아래 순서는 문체에만 해당합니다.
1. **`agent-tone` 이 1순위입니다.** 다른 스킬과 충돌하면 `agent-tone` 을 따릅니다. 단일 언어,
   인사말 배제, 금지 표현, 문장 종결, 형식 지정이 여기서 나옵니다.
2. **`humanizer` 는 영문 산문에만 적용합니다.** 패턴이 영어 문법과 철자 기준이라 국문에는 절반이
   헛돕니다. 로드 비용은 13k 토큰입니다. 국문에도 걸리던 여섯 항목은 `humanize-ko` 7~12번으로
   옮겼으므로 국문 산문에 `humanizer` 를 부르지 않습니다.
3. **국문 산문이면 `humanize-ko`, 영문 산문이면 `voice-en` 을 함께 적용합니다.** 서로 바꿔 쓰지
   않습니다.
4. **영문 뉴스체·헤드라인·카피 정리에는 `newsroom-style` 을 얹습니다.** 기계적 AP 규칙(숫자,
   날짜, 직함, 인용 부착 위치, 헤드라인)이 충돌하면 `newsroom-style` 이 이깁니다. 어조와 페르소나는
   `agent-tone` 이 이깁니다.
5. **프런트엔드 산출물에는 `design-taste-frontend` 를 적용합니다.** `impeccable` 은 이 저장소에
   동봉되지 않았습니다(5절 참조).

**겹치는 항목은 한 번만 손봅니다.** 셋씩 묶기, 굵게 처리 남용, 이모지는 국문에서는 `humanize-ko`
5·6번이 맡습니다.

## 2. 산출물 계열별로 함께 거는 스킬 (Scope)

`agent-tone` 안에서 어느 절과 `references/` 파일을 읽는지는 `agent-tone` §2 표가 정합니다. 이 표는
함께 거는 다른 스킬만 정합니다.

| 산출물 | 함께 거는 스킬 | 걸지 않는 것 |
| :--- | :--- | :--- |
| 대화형 답변, 코드 주석, 커밋 메시지, 리뷰 코멘트 | `agent-tone` | 문체 프로필, 문서형 규칙 |
| 국문 문서형 산출물: 메일 형식·보고 형식 문서, 서식·제출 문서 | `agent-tone` | `humanize-ko` 의 종결 변주·짧은 문장·목록 축소·리듬 변주·단정 우선, 보도체·다큐체 프로필 |
| 자료·안내 문서: 기준서, 명세, README, 운영 원칙 | `agent-tone` 메일 형식 | 문체 프로필, `newsroom-style` |
| 국문 일반 산문: 기사, 에세이, 서술형 브리핑 | `agent-tone` + `humanize-ko` | `humanizer`, `voice-en`, `newsroom-style` |
| 영문 산문 | `agent-tone` + `humanizer` + `voice-en`(뉴스체면 + `newsroom-style`) | `humanize-ko` |
| 프런트엔드 화면, 단일 HTML | `design-taste-frontend`. UX 문구는 `agent-tone` | React·Next·Tailwind 스택 지침(산출물이 단일 HTML 이면 버림) |
| 데이터 표, 로그, 체크리스트, 런시트, 스크립트 출력, 코드 | `agent-tone` §6 만 | 산문 문체 전부 |

**산문 교정 기준을 문서형 산출물에 그대로 걸지 않습니다.** 짧은 문장, 리듬 변주, 목록 축소, 단정 우선은
산문 기준입니다. 항목 단위로 검토하는 문서에 적용하면 정확도가 떨어집니다. 경계는
`agent-tone/references/document-rules.md` 가 정합니다.

**자료·안내 문서는 값과 지시가 본문입니다.**

- 값을 문장으로 녹이지 않습니다. 표 셀과 목록 라벨은 개조식 명사형으로 둡니다.
- `**라벨**: 설명` 형태의 인라인 목록은 이 계열에서 허용합니다(`humanizer` 의 굵게 남용 규칙의 예외).
- 피동·명사화(`확정됐습니다`, `확인이 필요합니다`)와 `~를 통해`·`~에 대해`·`~할 수 있도록` 같은 격식
  어휘는 이 계열에서 고치지 않습니다(`humanize-ko` 번역투 표의 예외).

**어느 계열이든 고치지 않는 것**: 인용문, 고유명사, 규정 문면, 이미 발신한 문서의 문면과 제목, 기능을 하는
표식(⚑, 🚫 같은 길잡이 기호).

## 3. 국문과 영문 규칙이 반대인 지점 (Inversions)

`humanize-ko` 의 규칙을 번역해서 영문에 쓰지 않습니다. 정반대인 항목이 있습니다.

- **인용 동사**: 국문은 변주하고, 영문은 `said` 하나로 갑니다. 영문에서 변주는 아마추어 표식이고
  `claimed`·`admitted` 는 필자 판단이 섞입니다.
- **인용 부착 위치**: 영문은 인용문이 앞에 오고 `Smith said` 가 뒤에 붙습니다.
- **시점 표기**: 영문은 "어제" 대신 요일을 씁니다.
- **헤징**: `allegedly`·`reportedly` 는 영문에서 헤징이 아니라 법적 장치라 남깁니다.

전체 대조는 `skills/voice-en/SKILL.md` 의 해당 절을 봅니다.

## 4. 항상 적용을 강제하는 방법 (Enforcement)

**스킬만 설치하면 항상 걸리지 않습니다.** 스킬은 설명 문구가 맞을 때나 이름으로 불릴 때 로드됩니다.
어조는 모든 산출물에 걸려야 하므로 강제 문구를 지시 파일에 넣습니다. `install/install.ps1`·`install.sh`
가 `CLAUDE.md`, `GEMINI.md`, `AGENTS.md` 에 같은 블록을 씁니다. 손으로 넣을 때는 아래를 붙입니다.

```markdown
# Communication Style Mandate

산문을 쓰거나 고칠 때는 호출 여부와 무관하게 항상 `agent-tone` 스킬을 적용한다.
적용 순서와 산출물별 범위는 `style-router` 스킬이 정하고, 충돌하면 `agent-tone` 이 우선한다.
대화형 답변도 대상이다.
```

## 5. `impeccable` 은 선택 도구입니다 (Optional companion, not bundled)

`impeccable`(Paul Bakaus)은 설계·시각화 문서에 쓰는 프런트엔드 스킬이고 **이 저장소에 들어 있지
않습니다.** 참조 자료와 스크립트가 JavaScript 모듈 107개에 약 3.2MB 라서 규칙 저장소가 담을 분량이
아닙니다. 필요하면 https://github.com/pbakaus/impeccable 에서 직접 설치합니다.

이 저장소는 그 코드를 재배포하지 않으므로 **`impeccable` 의 라이선스(Apache-2.0)는 이 저장소에
적용되지 않습니다.** 설치하면 그 사본은 사용자 환경에서 그 프로젝트의 라이선스를 따릅니다.

- **전체 절차**(PRODUCT.md → 방향 라운드 → 빌드 → 마감 리뷰 → 판정 라운드 → DESIGN.md)는
  **사용자가 명시적으로 요청했을 때만** 끝까지 돌립니다.
- 그 외에는 **금지 패턴, 타이포그래피, 색, 레이아웃 규율과 사전점검 목록까지만** 적용하고
  서브에이전트 체인은 돌리지 않습니다.
- `design-taste-frontend` 와 겹치는 항목은 한 번만 손봅니다.
