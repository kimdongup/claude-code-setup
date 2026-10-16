# usage.md — 템플릿 사용법

`template/` 을 실제 프로젝트에 적용하는 방법과, 각 구성 요소를 언제 어떻게 쓰는지를 정리한 문서입니다.
예시와 함께 보는 것을 추천합니다 → [`../example/walkthrough.html`](../example/walkthrough.html)

---

## 1. 설치 — 3분

### 방법 A. 새 프로젝트에 그대로 쓰기

```bash
git clone https://github.com/kimdongup/claude-code-setup.git claude-code-setup
cd my-new-project

cp -R claude-code-setup/template/.claude .
cp claude-code-setup/template/CLAUDE.md   ./CLAUDE.md      # 선택
cp claude-code-setup/template/.mcp.json  ./.mcp.json      # 선택

git add -A && git commit -m "chore: Claude Code 설정 적용"
```

이제 이 디렉터리에서 `claude` 를 실행하면 템플릿이 그대로 동작합니다.

### 방법 B. 템플릿을 저장소 안의 디렉터리로 유지

```bash
git clone https://github.com/kimdongup/claude-code-setup.git .claude-template
```

프로젝트마다 버전을 맞춰 가져오기 좋을 때. 실제 적용은 방법 A 와 동일합니다.

### 방법 C. 필요한 것만 골라 쓰기

전체 424개 파일을 다 받을 필요는 없습니다. 자주 쓰는 것만:

| 가져올 것 | 경로 | 언제 |
|---|---|---|
| 훅 | `.claude/settings.json` | 포맷·테스트·브랜치 보호를 자동화 |
| 에이전트 | `.claude/agents/` | 리뷰·디버깅·보안을 역할로 나눌 때 |
| 스킬 | `.claude/skills/<이름>/` | 특정 도메인 지식을 줄 때 |
| 명령 | `.claude/commands/` | 반복 지시를 슬래시 명령으로 |
| CI | `.github/workflows/` | 자동 리뷰를 PR에 붙일 때 |

---

## 2. 설치 직후 반드시 할 일

템플릿은 **예시 값**입니다. 그대로 켜면 잘못 동작합니다.

### 2-1. 훅을 한 번씩 직접 돌려본다

```bash
cd my-project

# ① main 브랜치에서 이게 막히면 정상입니다
bash -c '[ "$(git branch --show-current)" != "main" ] || { echo "{\"block\": true, \"message\": \"main 에서 편집 금지\"}" >&2; exit 2; }'
git checkout -b feat/작업시작
```

`settings.json` 의 `hooks` 블록을 열어보고, 이 프로젝트에 맞지 않는 훅은 **끄는 게 정답**입니다.
`example` 의 4단계가 이 과정을 그대로 녹화해 두었습니다.

### 2-2. Prettier 훅 확인

```json
{ "type": "command", "command": "npx prettier --write \"$CLAUDE_TOOL_INPUT_FILE_PATH\"" }
```

- Prettier 를 쓴다 → 그대로 둬도 됩니다
- Biome 를 쓴다 → 명령을 바꿉니다
- 포맷터를 안 쓴다 → `"command": "true"` 로 껍니다

### 2-3. 테스트 훅 확인

템플릿의 테스트 훅은 **Jest 전용 플래그**(`--findRelatedTests`)를 씁니다.

| 테스트 러너 | 바꿀 부분 |
|---|---|
| Jest | 그대로 사용 |
| Vitest | `--findRelatedTests` → `<파일경로>` |
| node:test | Jest 플래그 제거, 마지막에 `exit $exit_code` |
| pytest / go test | 셸 블록을 해당 명령으로 교체 |

> ⚠️ **가장 흔한 함정**: 훅이 실패를 알아차리고 `exit 1` 로 끝나야 Claude Code 가 멈춘다.
> `echo '{"feedback": "Tests failed"}'` 만 쓰고 `exit` 이 없으면, 화면에 실패가 떠도
> Claude Code 는 exit code 0 을 보고 다음 단계로 넘어간다.

### 2-4. `.mcp.json` 지우거나 채우기

```json
{ "mcpServers": { "jira": { "command": "npx", "args": ["-y", "@anthropic/mcp-jira"] } } }
```

쓰지 않는 MCP 서버는 **삭제**하세요. 켜져 있으면 세션마다 연결을 시도해 느려집니다.

---

## 3. 구성 요소 네 가지 — 무엇이 다른가

혼동하기 쉬우니 구분합니다.

| | 파일 | 역할 | 읽는 시점 | 예시 |
|---|---|---|---|---|
| **메모리** | `CLAUDE.md` | 이 프로젝트 규칙 | 매 세션 자동 | 외부 의존성 0개, main 에서 직접 편집 금지 |
| **지식** | `.claude/skills/*/SKILL.md` | 잘하는 방법 | 관련 작업할 때 | TDD 절차, 보안 점검 목록 |
| **역할** | `.claude/agents/*.md` | 일하는 방식 | 호출되거나 자동 선택 | 코드 리뷰, 원인 분석, 보안 |
| **명령** | `.claude/commands/*.md` | 반복 지시 | `/이름` 입력 시 | `/pr-review`, `/code-quality` |

판단 기준:

- **"우리 팀은 이렇게 한다"** → `CLAUDE.md`
- **"이 작업은 이렇게 하는 게 표준이다"** → `SKILL.md`
- **"이 작업은 따로 시켜주자"** → `agents/`
- **"내가 매번 같은 말을 한다"** → `commands/`

---

## 4. 자주 쓰는 명령

### 슬래시 명령 (6개)

```bash
/onboard          # 저장소 구조를 훑고 어디부터 볼지 정리
/pr-review        # 현재 브랜치 변경분을 리뷰
/pr-summary       # PR 설명문 초안 작성
/code-quality src # 디렉터리 지정 품질 점검
/docs-sync        # 코드와 문서의 불일치 찾기
/ticket PROJ-123  # 티켓 읽고 구현하고 상태 갱신
```

### 에이전트 호출 (9개)

```bash
@code-reviewer          # 구현 직후 — 정확성·회귀
@security-reviewer      # 신뢰 경계가 생겼을 때 — 경로·권한·시크릿
@root-cause-debugger    # 원인 미확인 상태 — 재현부터
@runtime-verifier       # 구현 완료 후 — 실제 동작으로 확인
@solution-architect     # 설계 선택지가 여러 개일 때
@codebase-mapper        # 낯선 저장소 탐색
@official-docs-researcher  # 최신 공식 문서가 필요할 때
@change-implementer     # 설계가 확정된 뒤 구현
@github-workflow        # 커밋·브랜치·PR
```

> 에이전트는 이름으로만 선택되지 않습니다. `.md` 앞부분의 **`description`** 문장이
> Claude 가 언제 꺼낼지 판단하는 기준입니다. 그 문장을 정밀하게 쓸수록 잘 고릅니다.

### 스킬 (86개)

```bash
/testing-patterns      # TDD 절차, 팩토리 패턴, 목킹
/systematic-debugging  # 4단계 디버깅 (원인 없이 수정 금지)
/caching               # 캐시 전략
/code-documenter       # 코드 문서화
```

전체 목록: [`../example/walkthrough.html`](../example/walkthrough.html) 또는 `.claude/skills/`

---

## 5. 훅 시점 — 언제 무엇이 도는가

```
사용자 프롬프트 입력
        │
        ├─ UserPromptSubmit ── 관련 스킬을 자동으로 붙여준다
        │
Claude 가 도구 호출
        │
        ├─ PreToolUse ──────── 위험한 행동 차단 (main 브랜치 편집 등)
        │
     실제 실행
        │
        └─ PostToolUse ─────── 자동 포맷 · 의존성 설치 · 테스트 실행
```

훅이 Claude Code 를 멈추게 하려면 **종료 코드가 중요**합니다.

| 종료 코드 | 의미 |
|---|---|
| `0` | 정상. Claude 는 그대로 진행 |
| `2` | **차단.** 메시지가 Claude 에게 전달되고 해당 도구 호출이 취소됨 |
| `1` | 오류. Claude 에게 실패로 보고됨 (차단용으로 `2` 가 더 명확) |

---

## 6. CI 로 고정하기

로컬에서 훅이 동작해도 서버에서는 아무도 안 봅니다. `.github/workflows/` 를 붙이세요.

```yaml
name: ci
on: pull_request:
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm test          # 테스트 훅과 같은 명령
      - run: npm run lint
```

`example/todo-app/.github/workflows/ci.yml` 이 실제 동작하는 예시입니다.

---

## 7. 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| 훅이 안 돈다 | `.claude/settings.json` 오류 | `node -e "JSON.parse(...)"` 로 검증 |
| 스킬이 안 읽힌다 | `SKILL.md` frontmatter 누락 | 첫 줄 `---`, `name`·`description` 확인 |
| 에이전트가 안 잡힌다 | `description`이 모호 | "~할 때 사용" 형식으로 구체화 |
| main 브랜치에서 막힌다 | PreToolUse 훅이 작동 중 | feature 브랜치로 이동 (정상 동작) |
| 매번 권한 묻는다 | `.claude/settings.local.json` 없음 | 허용 목록을 그 파일에 기록 |
| MCP 연결이 느리다 | 쓰지 않는 서버가 켜져 있음 | `.mcp.json` 에서 제거 |

---

## 8. 출처

이 템플릿은 아래 3개 저장소의 실사용 부분을 병합했습니다.

| 출처 | 제공한 것 |
|---|---|
| [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | `settings.json`, 훅, 에이전트 2개, 명령 6개, CI 워크플로 |
| [nidhinjs/prompt-master](https://github.com/nidhinjs/prompt-master) | 프롬프트 작성 스킬과 템플릿 레퍼런스 |
| [zebbern/claude-code-guide](https://github.com/zebbern/claude-code-guide) | 스킬 84개, 에이전트 7개, 시작 가이드 |

원본 저장소를 그대로 쓰셔도 됩니다. 병합본을 쓰는 이유는
**한 곳에 모아서 훅·CI까지 붙여 바로 쓸 수 있게** 하려는 것이고, 그 대가로
**텍스트를 실제로 읽고 프로젝트에 맞게 고쳐야 한다**는 점이 있습니다.

라이선스: MIT