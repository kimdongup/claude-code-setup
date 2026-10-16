# template/grok/

[Grok Build](https://docs.x.ai/build) 세트입니다.
[`../claude/`](../claude/) 세트와 **같은 내용**을 Grok 규약에 맞춰 옮겼습니다.

| 항목 | 개수 | 위치 |
|---|---|---|
| 스킬 | 86 | `.grok/skills/` |
| 에이전트 | 9 | `.grok/agents/` |
| 슬래시 명령 | 6 | `.grok/commands/` |
| 훅 | 3 | `.grok/hooks/` |
| MCP | 8 | `.mcp.json` |
| CI | 4 | `.github/workflows/` |

---

## 넣는 방법

```bash
cp -R template/grok/.grok      my-project/
cp    template/grok/AGENTS.md   my-project/
cp    template/grok/.mcp.json   my-project/          # 선택
```

프로젝트에서:

```bash
cd my-project
git checkout -b feat/작업시작   # PreToolUse 훅이 main 편집을 막습니다
grok --trust                  # ★ 첫 1회만. 이게 없으면 아무것도 안 읽힙니다
grok
```

## 신뢰(trust) 가 필수 — 가장 흔한 함정

Grok Build 는 **신뢰하지 않은 프로젝트의 설정을 조용히 건너뜁니다.**
`.grok/` 네이티브 경로든 `.claude/` 호환 경로든 **같습니다.**

```
grok inspect           → 스킬 22개(bundled) · 훅 0 · 지시문 0 · MCP 0
grok --trust inspect   → 스킬 113개 · 훅 3 · 지시문 1 · MCP 8
```

**에러가 나지 않습니다.** 그냥 0 개입니다. 파싱 문제가 아니라 신뢰 상태입니다.
원인을 찾으려면 파서를 의심하기 전에 `--trust` 를 먼저 붙여 보세요.

신뢰는 `~/.grok/trusted_folders.toml` 에 저장되므로 한 번만 하면 됩니다.
TUI 안에서는 `/hooks-trust` 로도 됩니다. 같은 결정이 프로젝트 MCP·LSP 신뢰도 함께 다룹니다.

## 실측 확인

```
grok --trust inspect
  Project Instructions (1)   ← AGENTS.md
  Skills (113)               ← 우리 스킬 86개 + bundled
  Agents (12)                ← 우리 에이전트 9개 + builtin 3개
  Hooks (3)
  MCP Servers (8)            ← .mcp.json
```

이 값이 나오면 설치가 끝난 것입니다. `Skills (22)` 만 나오면 신뢰 전입니다.

## 두 세트가 다른 것

| | [`../claude/`](../claude/) | 여기 |
|---|---|---|
| 설정 위치 | `.claude/` | `.grok/` |
| 지시 파일 | `CLAUDE.md` | `AGENTS.md` |
| 훅 정의 | `settings.json` 인라인 | `.grok/hooks/*.json` |
| 훅 입력 | `$CLAUDE_TOOL_INPUT_FILE_PATH` | stdin JSON |
| 차단 사유 | stderr `{"block":true}` | stdout `{"decision":"deny"}` |
| 에이전트 `model`·`effort` | 동작 | **제거됨** (무시되는 필드) |

스킬·명령·에이전트 본문·MCP·CI 는 동일합니다.
이유와 코드는 [`DIFF.md`](DIFF.md) 에 있습니다.

## hooks/

| 파일 | 이벤트 | 하는 일 |
|---|---|---|
| `hook-lib.sh` | — | 하네스 차이를 흡수하는 헬퍼 (`tool_input`, `deny`, `feedback`) |
| `10-pre-tool-use-branch-guard.sh` | PreToolUse | main/master 브랜치 편집 차단 |
| `20-post-tool-use-verify.sh` | PostToolUse | 테스트 자동 실행·의존성 설치·타입 검사·포맷 |
| `30-user-prompt-skill-hint.sh` | UserPromptSubmit | 관련 스킬 추천 |
| `hooks.json` | — | 위 훅의 등록 정의 |

`hook-lib.sh` 는 **Claude Code 에서도 그대로 동작**합니다.
직접 쓰고 싶다면 이 스크립트들만 `.claude/settings.json` 에 옮겨 넣으세요.

## 직접 해보기

[`../../example/grok/`](../../example/grok/) — Grok 규약으로 훅이 실제로 동작하는지
확인하는 6단계 데모입니다. 파서가 아니라 **디스크에서 실제 실행**해서 확인합니다.

```bash
./example/grok/run-demo.sh
```

MIT 라이선스.