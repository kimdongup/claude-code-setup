# template/

프로젝트에 복사해서 쓰는 Claude Code 설정입니다.

| 항목 | 개수 | 설명 |
|---|---|---|
| 스킬 | 86 | 도메인 지식과 작업 절차 (`SKILL.md`) |
| 에이전트 | 9 | 코드 리뷰·보안·디버깅 등 역할 |
| 슬래시 명령 | 6 | `/pr-review` · `/code-quality` 등 |
| 훅 | 4 | 자동 포맷 · 테스트 실행 · 브랜치 보호 |
| CI 워크플로 | 4 | PR 자동 리뷰 |

---

## 넣는 방법

```bash
cp -R template/.claude   my-project/
cp    template/CLAUDE.md my-project/CLAUDE.md     # 선택
cp    template/.mcp.json my-project/.mcp.json     # 선택
```

## 넣은 다음 반드시

**훅을 한 번씩 직접 돌려보세요.** 템플릿의 값은 예시입니다.

```bash
cd my-project
git checkout -b feat/작업시작     # PreToolUse 훅이 main 편집을 막습니다
```

설정에 들어 있는 훅이 이 프로젝트에 맞지 않으면 **끄는 게 정답**입니다.
자세한 확인 절차와 훅 실패 사례는 [`usage.md`](usage.md) 를 보세요.

## 파일 구성

```
template/
├── CLAUDE.md          스터터 프로젝트 기억 (복사 후 <각주> 를 채우세요)
├── usage.md           ★ 사용법 — 먼저 여기
├── .claude/
│   ├── settings.json  훅 · 환경변수
│   ├── settings.md    훅 설명서 (사람용)
│   ├── agents/        9개
│   ├── commands/      6개
│   ├── hooks/         4개
│   └── skills/        86개
├── .github/workflows/ 4개
├── .mcp.json          MCP 서버 예시
├── SHOWCASE_README.md     원본 저장소 README (ChrisWiles/claude-code-showcase)
└── PROMPT_MASTER_README.md 원본 저장소 README (nidhinjs/prompt-master)
```

## 바로 읽어보세요

- [`../example/walkthrough.html`](../example/walkthrough.html) — 이 템플릿을 실제로 굴려 보는 6단계 스크린샷 가이드
- [`../example/README.md`](../example/README.md) — 데모 실행법
- [`usage.md`](usage.md) — 설치 · 훅 검증 · 구성 요소 구분 · 트러블슈팅

MIT 라이선스.