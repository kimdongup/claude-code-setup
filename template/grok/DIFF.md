# DIFF.md — Claude Code 세트와 무엇이 어떻게 다른가

`template/grok/` 은 `template/claude/` 의 복사본이 아니라 **같은 내용을 두 하네스
규약에 맞춰 옮긴 것**입니다. 다른 부분은 여기 다 적었습니다.

실측 기준: `grok 1.0.60`. 신규 디렉터리마다 `grok inspect` 와 `grok --trust inspect` 를
비교해 신뢰 효과를 분리 확인했습니다.

---

## 1. PreToolUse — 차단 사유를 두 형식으로 동시에 출력

**Claude Code** 는 stderr 에 JSON, **Grok Build** 는 stdout 에 JSON 을 읽습니다.
필드 이름도 다릅니다.

| | 읽는 스트림 | 형식 |
|---|---|---|
| Claude Code | stderr | `{"block": true, "message": "..."}` |
| Grok Build | stdout | `{"decision": "deny", "reason": "..."}` |

그래서 이 세트는 **둘 다 씁니다.**

```bash
deny() {
  local reason="$1"
  printf '{"decision":"deny","reason":%s}\n' "$(json_str "$reason")"   # Grok
  printf '{"block": true, "message":%s}\n' "$(json_str "$reason")" >&2 # Claude
  exit 2
}
```

`exit 2` 는 양쪽 다 "차단"입니다. 이중 출력은 서로를 방해하지 않습니다.

## 2. 도구 입력 — 환경변수 vs stdin

가장 조용히 죽는 부분입니다.

| | 파일 경로를 주는 방법 |
|---|---|
| Claude Code | `$CLAUDE_TOOL_INPUT_FILE_PATH` 환경변수 |
| Grok Build | **stdin 으로 오는 JSON** 의 `toolInput.file_path` |

Claude Code 전용 변수를 그대로 쓰면 Grok 에서는 조건문이 그냥 false 가 되고,
훅은 **아무것도 하지 않은 채 exit 0** 으로 끝납니다. 에러가 없습니다.
자동 테스트·자동 포맷·의존성 설치 훅이 통째로 죽어도 아무도 모릅니다.

해결은 `hook-lib.sh` 의 `tool_input` 한 함수입니다.

```bash
file="$(tool_input file_path)"   # 하네스를 신경 쓰지 않는 단일 인터페이스
```

## 3. 훅 정의 위치

| | 위치 | 형식 |
|---|---|---|
| Claude Code | `.claude/settings.json` 안 `hooks` 블록 | 인라인 |
| Grok Build | `.grok/hooks/*.json` | **JSON 파일 단위** |

`.grok/hooks/` 에 스크립트만 두면 로드되지 않습니다. 정의 JSON 이 필요합니다.

```json
{ "hooks": { "PreToolUse": [
  { "matcher": "Edit|MultiEdit|Write|NotebookEdit",
    "hooks": [{ "type": "command",
                "command": "\"$GROK_WORKSPACE_ROOT\"/.grok/hooks/10-pre-tool-use-branch-guard.sh",
                "timeout": 5 }] } ] } }
```

## 4. 지시 파일

Grok Build 는 `AGENTS.md` 를 읽고, **`CLAUDE.md` 도 읽습니다.**
이 세트는 `AGENTS.md` 를 기본으로 둡니다. 다른 도구(Cursor, Codex 등)도
`AGENTS.md` 를 읽기 때문입니다. `CLAUDE.md` 로 쓰고 싶으면 파일 이름만 바꾸면 됩니다.

## 5. 에이전트 frontmatter — 무시되는 필드 제거

Grok Build 문서: *"Grok accepts `model`, `effort`, `license`, and `compatibility`
and does not apply them."*

`template/claude/.claude/agents/` 에는 이런 필드가 있습니다.

| 필드 | 개수 | Grok |
|---|---|---|
| `model` | 9 | 무시 |
| `effort` | 8 | 무시 |
| `permissionMode` | 8 | 미문서화 · 무시 추정 |

이 세트에서는 **제거**했습니다. 지우지 않으면 "`model: opus` 로 지정했는데
왜 안 되는지" 하는 착각이 생깁니다.

남긴 필드는 `name` · `description` · `tools` 입니다. 앞의 둘은 라우팅에 쓰이는
핵심 정보이고, `tools` 는 읽기 전용 서브에이전트를 정의합니다.

## 6. 그대로 가져가는 것

아래는 **두 세트가 바이트 단위로 동일**합니다.

- 스킬 86개 (`.claude/skills/` ≡ `.grok/skills/`)
- 슬래시 명령 6개
- 에이전트 9개의 **본문**
- `.mcp.json` (8개 서버)
- `.github/workflows/` (4개)
- 스킬 판정 엔진 `skill-eval.js` 와 규칙 `skill-rules.json`

두 세트의 일치 여부는 `tools/check-sync.py` 로 기계적으로 검사합니다.

---

## 확인 방법

```bash
cd template/grok && grok --trust inspect
```

기대 출력:

```
Project Instructions (1)
  └ /…/grok/Agents.md (project, ~900 tokens)
Skills (113)
  └ academic-paper-reviewer   project
Agents (12)
  └ code-reviewer            project
Hooks (3)
  └ command  project
MCP Servers (8)
```

## 7. 신뢰(trust) — 두 세트 공통의 최대 함정

`.grok/` 네이티브로 설치해도, `.claude/` 호환으로 설치해도 **신뢰 전에는 아무것도 읽히지 않습니다.**

```
grok inspect           → 스킬 22개(bundled) · 훅 0 · 지시문 0 · MCP 0
grok --trust inspect   → 스킬 113개 · 훅 3 · 지시문 1 · MCP 8
```

이 차이는 **경로와 무관합니다.** `.grok/` 로 설치했다고 해서 예외가 아닙니다.
(초기에实测하며 이 부분을 잘못 알고 있었고, 신규 디렉터리로 다시 확인해 바로잡았습니다.)

에러가 나지 않고 그냥 0 개이므로, 대개 "파서가 못 읽는다" 하고 오해합니다.
파서가 아니라 신뢰 상태입니다. 첫 실행은 `grok --trust` 로 시작하세요.

`.claude/` 로 설치한 세트는 신뢰 후에도 훅 개수가 다릅니다.
`.claude/settings.json` 인라인 정의(6개) vs `.grok/hooks/*.json` 파일 정의(3개) 때문입니다 —
Grok 세트는 비슷한 훅 3개를 합쳐서 등록했습니다.