---
name: style-router
description: 이 플러그인의 산문·프런트엔드 스킬이 겹칠 때 무엇을 먼저 적용할지 정한다. agent-tone, humanizer, humanize-ko, voice-en, newsroom-style, design-taste-frontend 의 적용 순서, 산출물 계열별 적용 범위, 국문과 영문 규칙이 반대인 지점, 항상 적용을 강제하는 방법. 글이나 화면을 쓰거나 고치기 전에 먼저 읽는다. Routing and precedence for the writing and design skills bundled in this plugin.
---

# Style router

이 플러그인에는 규칙이 여섯 벌 들어 있고, 일부는 같은 문장을 서로 다르게 고치라고 합니다. 순서를
정하지 않으면 마지막에 실행된 규칙이 이깁니다. 아래가 그 순서입니다.

## 1. 적용 순서 (Precedence)

1. **`agent-tone` 이 1순위입니다.** 다른 스킬과 충돌하면 `agent-tone` 을 따릅니다. 단일 언어,
   인사말 배제, 금지 표현, 문장 종결 패턴이 여기서 나옵니다.
2. **`humanizer` 는 산문이면 예외 없이 적용합니다.** 분량이 늘지 않습니다.
3. **국문 산문이면 `humanize-ko`, 영문 산문이면 `voice-en` 을 함께 적용합니다.** 서로 바꿔 쓰지
   않습니다. `humanizer` 가 잡는 패턴은 영어 기준이라 국문에는 절반만 걸립니다.
4. **영문 뉴스체·헤드라인·카피 정리에는 `newsroom-style` 을 얹습니다.** 기계적 AP 규칙(숫자,
   날짜, 직함, 인용 부착 위치, 헤드라인)이 충돌하면 `newsroom-style` 이 이깁니다. 어조와 페르소나는
   `agent-tone` 이 이깁니다.
5. **프런트엔드 산출물에는 `design-taste-frontend` 를 적용합니다.** `impeccable` 은 이 저장소에
   동봉되지 않았습니다(5절 참조).

**겹치는 항목은 한 번만 손봅니다.** 셋씩 묶기, 굵게 처리 남용, 이모지는 `humanizer` 와
`humanize-ko` 가 함께 지적합니다. 두 스킬이 같은 문장을 두 번 고치면 문장이 망가집니다.

## 2. 산출물 계열별 적용 범위 (Scope)

| 산출물 | 적용 | 적용하지 않음 |
| :--- | :--- | :--- |
| 대화형 답변, 채팅, 코드 주석, 커밋 메시지, 리뷰 코멘트 | `agent-tone` §1·§2·§2.1·§2.2·§3 | §4 문서 골격, §6 |
| 수신자가 있는 글(회신, 요청서, 전달본, 검토 결과) | `agent-tone` 전체. §4 골격을 그대로 씀 | 인사말과 종결 인사말은 §4 가 이미 금지 |
| 서식 문서, 제출 문서, 보고서 | `agent-tone` §6 이 산문 교정 기준보다 우선 | `humanize-ko` 의 짧은 문장·목록 축소·리듬 변주 |
| 국문 산문(기사, 안내문, 브리핑) | `humanizer` + `humanize-ko` + `agent-tone` | `voice-en`, `newsroom-style` |
| 영문 산문 | `humanizer` + `voice-en` (+ 뉴스체면 `newsroom-style`) | `humanize-ko` |
| 자료·안내 문서(기준서, 명세, README, 운영 원칙) | `agent-tone`. 값과 지시가 본문이므로 문체 프로필을 걸지 않음 | 보도체·뉴스체 프로필, `newsroom-style` |
| 프런트엔드 화면, 단일 HTML | `design-taste-frontend` 규칙. UX 문구는 `agent-tone` | React·Next·Tailwind 스택 지침(산출물이 단일 HTML 이면 버림) |
| 데이터 표, 로그, 체크리스트, 런시트, 스크립트 출력, 코드 | 없음. 개조식 명사형으로 두고 종결어미를 붙이지 않음 | 전부 |

**산문 교정 기준을 서식 문서에 그대로 걸지 않습니다.** 짧은 문장, 리듬 변주, 목록 축소, 단정
우선은 산문 기준입니다. 항목 단위로 훑고 심사하는 문서에 적용하면 정확도가 떨어집니다.
`agent-tone` §6 이 그 경계를 정합니다.

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
어조는 모든 산출물에 걸려야 하므로 강제 문구를 지시 파일에 넣습니다. `CLAUDE.md`, `GEMINI.md`,
`AGENT.md`, 또는 시스템 프롬프트에 아래를 붙입니다.

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
적용되지 않습니다.** 이름을 적고 주소를 걸어 두는 것만으로는 의무가 생기지 않습니다. 설치하면 그
사본은 사용자 환경에서 그 프로젝트의 라이선스를 따릅니다.

설치한 경우의 적용 강도는 이렇습니다.

- **전체 절차**(PRODUCT.md → 방향 라운드 → 빌드 → 마감 리뷰 → 판정 라운드 → DESIGN.md)는
  **사용자가 명시적으로 요청했을 때만** 끝까지 돌립니다.
- 그 외에는 **금지 패턴, 타이포그래피, 색, 레이아웃 규율과 사전점검 목록까지만** 적용하고
  서브에이전트 체인은 돌리지 않습니다.
- `design-taste-frontend` 와 겹치는 항목은 한 번만 손봅니다.
