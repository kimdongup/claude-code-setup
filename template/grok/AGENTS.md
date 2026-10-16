# AGENTS.md

> Grok Build 세트입니다. 이 파일은 세션마다 컨텍스트에 들어갑니다.
> 같은 내용의 `CLAUDE.md` 는 [`claude/` 세트](../claude/CLAUDE.md)에 있습니다.
> 설치법·차이점은 [`README.md`](README.md) 를 보세요.

## 이 프로젝트는 무엇인가

<!-- 한두 문장으로. Grok 는 이 설명을 모든 판단의 기준으로 삼습니다. -->
<프로젝트 이름> 은 <한 문장>. <만드는 것>을 위한 프로젝트입니다.

## 기술 스택

<!-- 여기 적지 않은 스택은 Grok 가 추측합니다. 적는 게 빠를수록 좋습니다. -->

- 언어/런타임:
- 프레임워크:
- 테스트 러너:
- 패키지 매니저:

## 명령

<!-- 자주 쓰는 것만. Grok 는 이걸로 명령을 직접 실행합니다. -->

```bash
<설치 명령>
<개발 서버 실행>
<테스트 실행>
<린트/포맷>
```

## 코딩 규칙

<!-- "하지 말 것"이 "할 것"보다 훨씬 자주 지켜지지 않습니다. -->

- 이 프로젝트는 반드시 <규칙>.
- <금지 사항> 은 쓰지 않는다.
- <금지 사항> 은 쓰지 않는다.

## 구조

<!-- 3줄 이상 깊게 들어가면 안 됩니다. -->

| 경로 | 역할 |
|---|---|
| `<경로>` | <무엇이 있는지> |

## 자주 하는 작업

- **<작업명>** — <어떻게 하는지 1~2줄>
- **<작업명>** — <어떻게 하는지 1~2줄>

## 주의 사항

- <잘못하면 돌아오기 어려운 것>
- <환경에 따라 달라지는 것>

---

## 이 템플릿이 함께 제공하는 것

`.grok/` 안에 들어 있는 설정입니다.

| 종류 | 경로 | 개수 | 역할 |
|---|---|---|---|
| 스킬 | `.grok/skills/` | 86 | 도메인 지식과 작업 절차 |
| 에이전트 | `.grok/agents/` | 9 | 코드 리뷰·보안·디버깅 등 역할 |
| 명령 | `.grok/commands/` | 6 | `/pr-review` 등 슬래시 명령 |
| 훅 | `.grok/hooks/` | 3 | 브랜치 보호·자동 검증 |
| MCP | `.mcp.json` | 8 | 외부 서비스 연동 |
| CI | `.github/workflows/` | 4 | PR 자동 리뷰 |

## 첫 실행에 반드시

프로젝트 훅과 MCP 는 **신뢰(trust) 없이는 조용히 로드되지 않습니다.**

```bash
grok --trust          # 최초 1회
# 그다음 TUI 안에서  /hooks-trust
```

확인은 이렇게 합니다.

```bash
grok inspect          # 신뢰 없이 확인 — 여기서 Hooks/스킬이 0 으로 나오면 신뢰 전입니다
grok --trust inspect  # 신뢰 후 확인 — 실제 로드 목록
```

> `grok inspect` 는 **신뢰 전 상태**를 보여줍니다. 스킬이 22개(bundled)만 뜨고
> 우리 스킬이 하나도 안 보이면, 파서가 아니라 신뢰 문제입니다.

## Claude Code 세트와 무엇이 다른가

| | `template/claude/` | `template/grok/` |
|---|---|---|
| 설정 위치 | `.claude/` | `.grok/` |
| 지시 파일 | `CLAUDE.md` | `AGENTS.md` |
| 훅 정의 | `settings.json` 안에 인라인 | `.grok/hooks/*.json` |
| 훅 입력 | `$CLAUDE_TOOL_INPUT_FILE_PATH` | stdin JSON (`toolInput.file_path`) |
| 차단 사유 | stderr `{"block":true}` | stdout `{"decision":"deny"}` |
| 에이전트 `model` | 동작 | **무시됨** → 세트에서 제거 |
| 에이전트 `effort` | 동작 | **무시됨** → 세트에서 제거 |

스킬 86개·명령 6개·에이전트 본문·MCP·CI 는 **두 세트가 동일합니다.**
다른 것은 위 표뿐입니다.

차이점의 이유는 [`DIFF.md`](DIFF.md) 에 코드로 정리해 두었습니다.

## 출처

| 출처 | 제공한 것 |
|---|---|
| [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | 훅, 에이전트 2개, 명령 6개, CI 워크플로 |
| [nidhinjs/prompt-master](https://github.com/nidhinjs/prompt-master) | 프롬프트 작성 스킬과 레퍼런스 |
| [zebbern/claude-code-guide](https://github.com/zebbern/claude-code-guide) | 스킬 84개, 에이전트 7개, 시작 가이드 |

라이선스: MIT