# 🏆 Golden Master Sample: High-Quality Support & Consultation (Generalized)

이 문서는 아키텍처 검토, API 계약, 네트워크 방화벽 등 기업 내 고보안성 질문에 대응하면서 선제적인 PoC 성능 개선안을 제안한 **최고 사양의 커뮤니케이션 레퍼런스(골든 마스터)**입니다. 본 가이드라인의 싱글 랭기지(국문 전용) 표준이 적용되어 영어 번역부 없이 국문으로만 완벽하게 작성되었으며, 모든 기밀 벤더 및 자사 정보가 완벽히 마스킹되어 있습니다.

---

## 🟢 한국어 본문 (Korean Original)

Jane Doe 님, 안녕하세요.
AI Labs John Doe입니다.

보안 검토 결과와 전제 조건을 정리해 공유해 주셔서 감사합니다.
세 가지 모두 말씀하신 방향으로 진행 가능하며 ZDR만 별도 신청·검토 절차가 있습니다.
항목별 확인 결과를 아래에 말씀드립니다.
그리고 마지막에 PoC에서의 데이터 접근과 관련해서 제안사항을 두었으니 확인 부탁드립니다.

### 1. MCP 구조

**저희가 이해한 문의 의도**: MCP에 접속하는 쪽(MCP client)은 반드시 사내 EC2 앱이어야 하고 AI Labs 서버가 사내 MCP에 접속하는 일은 없어야 한다는 전제에서, Agent SDK 구성이 가능한지 확인.

네, 전제 조건대로 구성됩니다.
Agent SDK는 귀사 EC2 안에서 SDK에 포함된 실행 프로세스(Agent Code)를 실행하고 이 프로세스가 MCP client가 되어 사내 MCP 서버에 접속합니다.
접속 방식은 같은 서버 안의 프로세스(stdio)도 되고 사내망 HTTP 주소도 됩니다.
사내망에서만 접근 가능한 주소면 충분하고 외부에서 접근 가능할 필요가 없습니다.
이 구성에서는 AI Labs 서버가 귀사 MCP 서버에 접속하지 않습니다.
* 관련 문서: https://code.ai-labs-provider.com/docs/en/agent-sdk/hosting
* 관련 문서: https://code.ai-labs-provider.com/docs/en/agent-sdk/mcp

한 가지 보안 검토에 반영해 주시면 좋을 점이 있습니다.
이 구조에서 AI Labs API로 전송되는 데이터는 툴 실행 결과만이 아닙니다.
(1) 툴 정의(툴 이름·설명·입력 형식), (2) 모델이 만든 툴 입력(예: 실행할 SQL), (3) 시스템 프롬프트와 대화 이력, (4) 툴 실행 결과(조회된 데이터)가 함께 전송됩니다.
모델이 조회 결과를 읽고 다음 판단을 해야 하므로, Enterprise Data Platform에서 조회된 데이터의 내용은 AI Labs API로 전송됩니다.
MCP 서버 설정(주소·인증 정보)을 Agent SDK가 AI Labs API로 보내는 일은 없습니다.
다만 모델이 읽는 내용(툴 설명, MCP 서버가 연결 시 보내는 설명문, 오류 메시지, 모델이 읽은 파일 등)은 API로 전송되므로, 툴 설명이나 조회 결과에 접속 정보가 섞이지 않도록 구성해 주시면 됩니다.
설정에 적은 MCP 서버 이름은 툴 이름의 일부로 포함됩니다.
* 관련 문서: https://code.ai-labs-provider.com/docs/en/agent-sdk/agent-loop

Messages API의 MCP connector(mcp_servers 파라미터)는 이해하신 대로 AI Labs 서버가 MCP client가 되어 귀사 MCP 서버 주소로 직접 접속하는 방식입니다.
이 방식은 MCP 서버가 인터넷에서 접근 가능한 HTTP 주소여야 하고 Zero Data Retention(ZDR) 대상도 아닙니다.
Agent SDK는 이 방식을 사용하지 않습니다.
* 관련 문서: https://platform.ai-labs-provider.com/docs/en/agents-and-tools/mcp-connector

---

### 2. API 계약

**저희가 이해한 문의 의도**: "기업용 라이선스"와 "당사 데이터를 학습·서비스 개선에 사용하지 않을 것" 두 조건을 만족하려면 별도의 엔터프라이즈 계약이 필요한지, 그리고 ZDR 적용 가능 여부와 신청 절차 확인.

별도의 엔터프라이즈 계약 없이, 현재 상용 약관과 DPA로 아래와 같이 다뤄집니다.
따라서 클라우드 마켓플레이스를 거치지 않고 AI Labs API(1st party API, api.ai-labs-provider.com)를 직접 사용하실 수 있습니다.

- **(기업용 라이선스)** API 서비스는 개인용 서비스가 아니라 기업·조직용 상용 약관(Commercial Terms of Service)이 적용되는 서비스입니다. 약관 원문에도 "Services under these Terms are not for consumer use"라고 명시되어 있습니다. 영업 계약 없이 Console에서 직접 조직을 만드는 경우(셀프서브 조직)에도 동일하게 이 약관이 적용되며 약관에 동의하거나 서비스를 처음 이용한 시점 중 빠른 쪽부터 효력이 있습니다. 조직 생성 시 약관 동의는 회사를 대표해 하는 것이므로, 권한 있는 담당자가 회사 명의로 진행해 주시면 됩니다.
  * 관련 문서: https://www.ai-labs-provider.com/legal/commercial-terms

- **(학습 미사용)** 같은 약관에 "AI Labs may not train models on Customer Content from Services"라고 명시되어 있습니다. 즉 귀사가 입력한 내용과 모델의 출력(Customer Content)으로 모델을 학습하지 않습니다. 약관상 귀사가 입력한 내용과 출력(Customer Content)은 귀사의 기밀 정보로 취급됩니다. AI Labs는 이를 약관에 따른 권리 행사와 의무 이행 범위에서만 사용할 수 있습니다. 개인정보 처리는 약관에 포함된 데이터 처리 부속서(DPA)에 따라, 법령상 요구되는 경우를 제외하면 서비스 제공·유지(품질·보안 확인 포함) 목적으로 한정됩니다. '서비스 개선'이라는 표현이 약관에 따로 있지는 않으며 데이터 사용 범위는 위 약관 조항들이 정한 범위로 한정됩니다.
  * 관련 문서: https://www.ai-labs-provider.com/legal/commercial-terms
  * 관련 문서: https://www.ai-labs-provider.com/legal/data-processing-addendum

엔터프라이즈 계약은 위 조건의 전제가 아니라, 협의 가격이나 인보이스 결제, 서명본 계약이 필요하실 때 선택하시는 것입니다. 계약 형태·가격·절차는 담당 Account Manager인 Alex가 별도로 안내드리겠습니다.

- **(데이터 보존과 ZDR)** ZDR을 적용하지 않는 표준 정책에서는 입력·출력을 최대 30일까지만 보관한 뒤 삭제합니다.
  * 관련 문서: https://code.ai-labs-provider.com/docs/en/data-usage
  ZDR이 적용되면 API 응답을 돌려드린 뒤에는 입력·출력을 저장하지 않습니다. 다만 법적으로 보존이 요구되거나 AI Labs의 자동 안전 시스템에 의해 위반 의심으로 표시된 경우에는 ZDR 적용 중에도 예외적으로 보존될 수 있습니다(최대 2년). 이 예외는 ZDR을 적용하지 않는 표준 정책에서도 동일하게 적용됩니다. ZDR은 Console에서 직접 켜는 설정이 아닙니다. 적용을 원하시면 말씀 주세요. 검토에서는 표준 보존 정책(최대 30일)으로는 맞추기 어려운 규제·계약·사내 보안 정책상의 요구 사항이 있는지를 확인하므로, 그 내용을 함께 알려주시면 귀사 조직 단위로 검토를 진행합니다. 승인 여부와 적용 시점은 검토 결과에 따라 정해집니다. ZDR 적용 전에 시작하시는 호출에는 위 표준 정책(최대 30일 보관)이 적용됩니다. 일부 기능(MCP connector, Files API, Batch API 등)은 ZDR 대상이 아니지만 말씀하신 구조(EC2 앱이 MCP client)는 일반 Messages API 호출이므로 ZDR 대상입니다. 공식 문서에도 ZDR이 적용된 상용 조직의 API 키로 Agent Code(Agent SDK 런타임)를 사용하는 경우 그 범위에 포함된다고 명시되어 있습니다. Agent SDK 런타임이 보내는 사용 통계(프롬프트·코드·파일 경로는 포함되지 않음)는 ZDR과 별개로 보관될 수 있으며 3번에 적은 환경 변수로 끌 수 있습니다. 일부 모델은 데이터 보존 요건 때문에 ZDR 적용 대상이 아닐 수 있으니, 사용하실 모델이 정해지면 함께 확인드리겠습니다.
  * 관련 문서: https://platform.ai-labs-provider.com/docs/en/manage-ai-labs/api-and-data-retention

- **(클라우드 마켓플레이스 경로)** 마켓플레이스를 통한 AI Platform on Cloud에도 같은 상용 약관과 같은 데이터 보존 정책이 적용되며 ZDR도 신청하실 수 있습니다. 다만 클라우드 콘솔에서 가입하면 기존 조직과 별개의 AI Labs 조직이 새로 만들어지고 API 호출 주소도 다릅니다(3번 참고). 서드파티 완전 관리형 모델 서비스는 데이터를 처리하는 주체(데이터 처리자)가 AI Labs가 아니라 클라우드 제공사인 별도 경로입니다.
  * 관련 문서: https://platform.ai-labs-provider.com/docs/en/build-with-ai-labs/ai-platform-on-cloud

별도 계약 절차 없이 Console에서 조직을 만들고 약관에 동의한 뒤 크레딧을 등록하시면 관리형 서비스 없이 AI Labs API를 사용하실 수 있습니다. ZDR은 위와 같이 별도 신청·검토 대상입니다.

---

### 3. 방화벽

**저희가 이해한 문의 의도**: 사내 EC2에서 api.ai-labs-provider.com으로 나가는 연결을 IP 기반으로 허용해야 하는데, 특정 대역이 맞는지와 고정 대역인지 확인.

확인되었습니다.
제시된 대역(192.168.1.0/24 등)이 맞습니다.
공식 문서 기준으로 AI Labs가 연결을 받는 주소(Inbound)는 IPv4 192.168.1.0/24, IPv6 2001:db8::/32 입니다.
귀사 방화벽에서는 EC2에서 api.ai-labs-provider.com으로 나가는 연결의 목적지 대역으로 등록하시면 됩니다.
문서에 고정 주소("fixed")이며 사전 공지 없이 변경하지 않는다("will not change without notice")고 명시되어 있습니다.
* 관련 문서: https://platform.ai-labs-provider.com/docs/en/api/ip-addresses

같은 문서의 Outbound 대역은 AI Labs 쪽에서 고객 서버로 접속할 때(예: MCP connector) 쓰는 대역입니다.
말씀하신 구조에서는 AI Labs에서 귀사로 들어오는 연결이 없으므로 이 대역은 등록하지 않으셔도 됩니다.

Agent SDK 런타임은 모델 호출 외에 선택적 트래픽(사용 통계 등)을 보낼 수 있습니다.
환경 변수 AGENT_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 로 끌 수 있고 접속 호스트 전체 목록은 아래 문서에 있습니다.
이 설정이면 외부 접속은 api.ai-labs-provider.com과 사내 MCP 서버 정도입니다.
사내 MCP를 패키지 관리자로 띄우거나(패키지 저장소 접근 필요) 웹 페이지 조회(WebFetch) 툴을 쓰시면(조회 대상 사이트 접근 필요) 추가 호스트 허용이 필요합니다.
* 관련 문서: https://code.ai-labs-provider.com/docs/en/network-config

서드파티 관리형 AI 서비스는 호출이 각 클라우드의 엔드포인트로 가므로 AI Labs IP 등록 대상이 아니며 이해하신 대로 각 클라우드의 프라이빗 연결(PrivateLink / Private Service Connect)로 구성하실 수 있습니다.
구성은 각 클라우드의 문서를 기준으로 하시면 됩니다.

참고로 마켓플레이스 경로(AI Platform on Cloud)는 호출 주소가 aws-external-ai-labs.{region}.api.aws 이고 클라우드 IP 대역을 사용하며 공식 문서에 프라이빗 연결 지원이 명시되어 있습니다.
api.ai-labs-provider.com을 직접 호출하는 구간은 위 IP 대역 허용 방식으로 구성하시면 됩니다.
프라이빗 연결이 꼭 필요하시다면 마켓플레이스 경로도 검토하실 수 있습니다.
이 경로에서도 모델 추론은 AI Labs 인프라에서 처리되어, 클라우드사가 직접 데이터 처리 주체인 서드파티 관리형 서비스와는 구조가 다릅니다.
* 관련 문서: https://platform.ai-labs-provider.com/docs/en/build-with-ai-labs/ai-platform-on-cloud

---

### [선제적 제안 및 보완 사항 (Value-Add Proactive Consulting)]

PoC 준비와 관련해 제안 하나 드립니다.

PoC에서 사용하실 데이터 접근 MCP는 기존 Internal Data MCP(Enterprise Data Platform 조회용 MCP)를 그대로 쓰고, MCP에 넘길 입력을 만드는 과정을 안내하는 Skill을 업데이트하는 방식으로 접근해 보시면 어떨까요?
Internal Data MCP 자체도 개선하면 좋겠지만, PoC 기간 안에 결과를 내려면 그 부분은 다음 단계로 두는 것이 맞아 보입니다.
대신 지난번에 보내 주신 Skill(data-platform-analysis)을 개선하면 응답 시간을 줄여 볼 여지가 있어 보입니다.
저희가 SKILL.md를 살펴본 결과, 질문 하나에 참고 파일 읽기와 MCP 조회가 여러 번 일어나는 구조가 응답 시간에 영향을 주는 것으로 보입니다.
그래서 호출 횟수를 줄이는 방향으로 개선 아이디어를 정리해 보았습니다(예시 쿼리 추가, 기준정보 조회 통합, 참고 파일의 핵심 내용을 본문으로 이동 등).
다만 이 내용은 SKILL.md의 지시 내용과 가상 환경 비교로 추정한 것이라, 실제 환경에서 확인해 보셔야 합니다.

정확도 쪽으로도 확인해 보시면 좋을 부분(개인정보 최소 인원 집계 방식, NPS 산식의 분모, 전환율 정의)을 함께 적어 두었습니다.
Skill 검토 자료(개선 포인트 정리, 개선안 초안 등)를 이 메일에 첨부합니다.
개선안 초안에는 원본에 없는 값(필드 목록, 국가 대응표, 예시 쿼리 등)을 TODO로 비워 두었으니, 채우기 전에는 배포하지 마시고 참고용으로 봐 주시면 됩니다.
참고로 스키마 설명, Golden query, SQL 작성 규칙은 MCP 쪽이 아니라 Agent SDK의 Skills(EC2 안에 두는 SKILL.md 파일)나 시스템 프롬프트로 에이전트 쪽에 둘 수 있습니다.
* 관련 문서: https://code.ai-labs-provider.com/docs/en/agent-sdk/skills

Enterprise Data Platform 정비와 Skill 개발 진행 상황도 공유해 주셔서 감사합니다.
진행하시면서 막히는 부분이 있으면 언제든 말씀 주세요.

감사합니다.
AI Labs John Doe 드림
