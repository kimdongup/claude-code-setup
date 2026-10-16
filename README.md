# claude-code-setup

Claude Code 설정을 한 곳에 모아 둔 템플릿과, 그것을 실제 프로젝트에 적용한 기록입니다.

```
.
├── template/          ← 설정 템플릿 (이 저장소의 본체)
│   ├── .claude/         스킬 86 · 에이전트 9 · 명령 6 · 훅 4
│   ├── CLAUDE.md        프로젝트 기억
│   ├── usage.md         ★ 사용법 — 여기서부터 읽으세요
│   └── .github/         CI 워크플로
└── example/           ← 할 일 앱 데모 (실행해 보는 용도)
    ├── walkthrough.html ★ 단계별 스크린샷 가이드
    ├── run-demo.sh      한 번에 전부 돌리기
    └── steps/           6개 단계 스크립트
```

---

## 바로 해보기

```bash
git clone https://github.com/kimdongup/claude-code-setup.git
cd claude-code-setup

open example/walkthrough.html   # 스크린샷 가이드
open template/usage.md          # 사용법
./example/run-demo.sh           # 데모를 직접 실행
```

프로젝트에 적용하는 방법:

```bash
cp -R template/.claude  my-project/
cp    template/CLAUDE.md my-project/CLAUDE.md     # 선택
cp    template/.mcp.json my-project/.mcp.json     # 선택
```

---

## 이 저장소가 말하는 것

Claude Code 설정을 모으는 일 자체는 어렵지 않습니다. 어려운 건
**모아 놓고 실제 프로젝트에서 안 깨지게 만드는 것**입니다.

그래서 예시(`example/`)를 전부 실제로 실행해 두었습니다. 그 과정에서 템플릿의 실제 결함도 나왔습니다.

### 발견한 함정 — 훅이 실패를 모른다

템플릿의 테스트 훅 원문:

```bash
if [ $exit_code -eq 0 ]; then
  echo '{"feedback": "Tests passed."}'
else
  echo '{"feedback": "Tests failed. See output above."}' >&2
fi          # ← 여기서 끝. exit 코드는 0
```

테스트가 깨져도 메시지만 찍고 **종료 코드가 0** 입니다. Claude Code 는 그걸 보고
문제가 없었다고 판단하고 다음 단계로 넘어갑니다. `example/` 4단계가 이걸 그대로 재현합니다.

```bash
  {"feedback": "Tests failed. See output above."}
  훅 종료 코드: 0          ← Claude Code 는 여기서 멈추지 않는다
```

고친 버전은 실패 분기에 `exit 1` 을 넣습니다.

### 발견한 함정 2 — 훅은 예시 값이다

테스트 훅이 `npm test -- --findRelatedTests` 를 호출하는데, 이건 **Jest 전용 플래그**입니다.
Vitest·node:test·pytest 프로젝트에서는 그대로 실패합니다.

설치 직후 반드시 훅을 한 번씩 직접 돌려보세요. 안 맞으면 **끄는 게 정답**입니다.

---

## 구성 요소 네 가지

| | 파일 | 무슨 일을 하나 | 언제 읽히나 |
|---|---|---|---|
| 메모리 | `CLAUDE.md` | 이 프로젝트 규칙 | 매 세션 |
| 지식 | `.claude/skills/*/SKILL.md` | 잘하는 방법 | 관련 작업할 때 |
| 역할 | `.claude/agents/*.md` | 일하는 방식 | 호출 또는 자동 선택 |
| 명령 | `.claude/commands/*.md` | 반복 지시 | `/이름` 입력 |

자세한 구분 기준과 훅 시점·종료 코드 규약 → [`template/usage.md`](template/usage.md)

---

## 출처

세 저장소의 실사용 부분을 병합했습니다.

| 출처 | 제공한 것 |
|---|---|
| [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | `settings.json`, 훅, 에이전트 2개, 명령 6개, CI 워크플로 |
| [nidhinjs/prompt-master](https://github.com/nidhinjs/prompt-master) | 프롬프트 작성 스킬과 템플릿 레퍼런스 |
| [zebbern/claude-code-guide](https://github.com/zebbern/claude-code-guide) | 스킬 84개, 에이전트 7개, 시작 가이드 |

병합본의 대가는 **텍스트를 실제로 읽고 프로젝트에 맞게 고쳐야 한다**는 것입니다.
그래서 사용법 문서도, 실제로 실패해 보는 예제도 함께 두었습니다.

MIT 라이선스. 원본 저장소의 라이선스도 동일합니다.