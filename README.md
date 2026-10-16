# claude-code-setup

Claude Code 설정을 한 곳에 모아 둔 템플릿입니다. **Claude Code 용**과 **Grok Build 용**
두 세트로 나뉘어 있으며, 두 세트는 공유 콘텐츠가 바이트 단위로 같습니다.

```
.
├── template/
│   ├── claude/            ← Claude Code 세트
│   │   ├── .claude/         스킬 86 · 에이전트 9 · 명령 6 · 훅 4
│   │   ├── CLAUDE.md        프로젝트 기억
│   │   ├── usage.md         ★ 사용법
│   │   └── .github/         CI 워크플로 4
│   └── grok/              ← Grok Build 세트 (같은 내용, 다른 규약)
│       ├── .grok/           스킬 86 · 에이전트 9 · 명령 6 · 훅 3
│       ├── AGENTS.md        프로젝트 기억
│       ├── DIFF.md          ★ 두 세트의 차이를 코드로 정리
│       └── README.md
│
├── example/
│   ├── claude/            ← 6단계 스크린샷 데모 + walkthrough.html
│   └── grok/              ← 같은 데모, Grok 규약으로 실행
│
├── tools/check-sync.py    두 세트가 어긋나지 않았는지 검사
└── run-all.sh             두 세트 한 번에 확인
```

---

## 바로 해보기

```bash
git clone https://github.com/kimdongup/claude-code-setup.git
cd claude-code-setup

./run-all.sh              # 두 세트 데모 + 동기화 검사
open example/claude/walkthrough.html
open example/grok/walkthrough.html
```

### 적용하기 — Claude Code

```bash
cp -R template/claude/.claude  my-project/
cp    template/claude/CLAUDE.md my-project/
```

### 적용하기 — Grok Build

```bash
cp -R template/grok/.grok      my-project/
cp    template/grok/AGENTS.md  my-project/

cd my-project && grok --trust   # ★ 첫 1회. 이게 없으면 아무것도 안 읽힙니다
```

---

## 두 세트의 차이

| | [`template/claude/`](template/claude/) | [`template/grok/`](template/grok/) |
|---|---|---|
| 설정 위치 | `.claude/` | `.grok/` |
| 지시 파일 | `CLAUDE.md` | `AGENTS.md` |
| 스킬 · 명령 · CI | 스킬 86 · 명령 6 · 워크플로 4 | **동일** |
| 훅 정의 | `settings.json` 인라인 (6개) | `.grok/hooks/*.json` (3개) |
| 훅 입력 | `$CLAUDE_TOOL_INPUT_FILE_PATH` | stdin JSON |
| 차단 사유 | stderr `{"block":true}` | stdout `{"decision":"deny"}` |
| 에이전트 `model`·`effort` | 동작 | **제거됨** (Grok 는 무시) |

같은 것은 복사가 아니라 **동등성 검사**로 보장합니다.

```
$ python3 tools/check-sync.py
  ✔ skills    391개 동일
  ✔ commands  6개 동일
  ✔ agents     9개 · 무시필드 제거 9개
  ✔ mcp       동일
  ✔ CI        4개 동일
  ✔ hooks      Grok 훅은 하네스 독립

  두 세트는 의도한 차이만 가지고 있습니다.
```

---

## Grok 세트를 만들면서 발견한 것

### 1. 훅이 조용히 죽는다

Claude 전용 환경변수를 그대로 쓰면 Grok 에서는 조건문이 false 가 되고
**아무것도 하지 않은 채 exit 0** 으로 끝납니다. 에러가 없습니다.

```
── Claude Code 규약으로 실행 ──
{"feedback": "Running tests..."}     ← 동작

── Grok 규약으로 실행 ──
(출력 없음)  종료 코드 0             ← 죽었다
```

해결은 `.grok/hooks/hook-lib.sh` 의 `tool_input` 한 함수입니다.
같은 훅이 두 하네스에서 같은 결과를 냅니다. → [`DIFF.md` 2장](template/grok/DIFF.md)

### 2. 차단 사유가 사라진다

`exit 2` 는 양쪽 다 차단이라 기능은 유지됩니다. 하지만 Claude 는 stderr,
Grok 는 stdout 을 읽고 필드 이름도 다릅니다. `deny()` 가 둘 다 출력합니다.

### 3. 신뢰(trust) 가 없으면 아무것도 안 보인다

`.grok/` 네이티브로 설치해도 예외가 아닙니다.

```
grok inspect           → 스킬 22개(bundled) · 훅 0 · 지시문 0 · MCP 0
grok --trust inspect   → 스킬 113개 · 훅 3 · 지시문 1 · MCP 8
```

에러가 나지 않습니다. "Grok 가 우리 스킬을 못 읽는다" 하고 오해하기 쉬우므로
첫 실행은 `--trust` 로 시작하세요.

---

## 이 저장소의 성격

Claude Code 설정을 모으는 일은 어렵지 않습니다. 어려운 건 **모아 놓고
실제 프로젝트에서 안 깨지게 만드는 것**입니다.

그래서 두 세트 모두 실제 실행으로 검증했습니다 (`./run-all.sh`).
그 과정에서 템플릿의 실제 결함도 나왔습니다.

| 발견 | 어떻게 아는지 |
|---|---|
| 테스트 훅이 실패 분기에 `exit` 이 없다 | 화면에 "Tests failed" 가 떠도 종료 코드 0 |
| 테스트 훅이 Jest 전용 플래그를 쓴다 | node:test 프로젝트에서 그대로 실패 |
| Claude 전용 환경변수는 Grok 에서 조용히 무시 | `example/grok` 4단계 |

그리고 결정적으로 — **판정 로직의 대부분이 이미 모델 비의존입니다.**
`review.mjs` · `security-audit.mjs` · `quality.mjs` · CI 는 순수 Node.js 와 셸이고,
모델이 Claude 이든 Grok 이든 심지어 모델 없이도 같은 판정을 냅니다.
에이전트를 스크립트로 옮겨 둔 결과이고, 이 덕분에 도구를 바꿔도 품질이 흔들리지 않습니다.

---

## 출처

| 출처 | 제공한 것 |
|---|---|
| [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | `settings.json`, 훅, 에이전트 2개, 명령 6개, CI 워크플로 |
| [nidhinjs/prompt-master](https://github.com/nidhinjs/prompt-master) | 프롬프트 작성 스킬과 레퍼런스 |
| [zebbern/claude-code-guide](https://github.com/zebbern/claude-code-guide) | 스킬 84개, 에이전트 7개, 시작 가이드 |

MIT 라이선스. 원본 저장소의 라이선스도 동일합니다.

- [`template/claude/usage.md`](template/claude/usage.md) — Claude Code 사용법
- [`template/grok/README.md`](template/grok/README.md) — Grok Build 사용법