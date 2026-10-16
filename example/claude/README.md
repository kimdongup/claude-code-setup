# example/claude/

`template/claude/` 을 실제로 굴려 보는 6단계 기록입니다.
**이 폴더의 스크립트를 실행하면 `todo-app/` 이 새로 만들어집니다.** (결과물은 `.gitignore` 대상)

```bash
./run-demo.sh          # 처음부터 6단계 실행 + walkthrough.html 갱신
./run-demo.sh --keep   # 만들어진 앱을 남기고 단계만 다시 실행
./run-demo.sh 3 5      # 3~5단계만
open walkthrough.html  # 스크린샷이 담긴 가이드 열기
```

요구 환경: `bash`, `node` 20+, `python3`, `git`. 외부 의존성 설치가 전혀 없습니다.

> Grok Build 세트의 데모는 [`../grok/`](../grok/) 에 있습니다.
> 같은 6단계를 Grok 규약으로 실행하며, 4단계 내용이 다릅니다.

---

## 결과물

| 경로 | 내용 | git |
|---|---|---|
| `walkthrough.html` | 단계별 스크린샷 + 설명 (단일 파일, 외부 자원 없음) | ✅ 커밋 |
| `steps/*.sh` | 6개 단계 스크립트 | ✅ 커밋 |
| `run-demo.sh` | 전체 실행기 | ✅ 커밋 |
| `lib.sh` | 공용 헬퍼 | ✅ 커밋 |
| `make-walkthrough.py` | 로그 → HTML 생성기 | ✅ 커밋 |
| `todo-app/` | 실행 결과 (만들어진 할 일 앱) | ❌ 무시 |
| `logs/` | 실행 로그 (스크린샷 원본) | ❌ 무시 |

---

## 6단계 요약

| 단계 | 무슨 일 | 건드린 템플릿 요소 |
|---|---|---|
| 1 | 빈 폴더에서 시작, 템플릿 적용 | `.claude/settings.json` |
| 2 | 프로젝트 규칙을 `CLAUDE.md` 에 기록 | `CLAUDE.md` |
| 3 | TDD로 도메인 구현 (red→green→refactor 3회) | `skills/testing-patterns` |
| 4 | 훅을 직접 돌려보고 함정을 찾아 고침 | `settings.json` 훅 블록 |
| 5 | 서브에이전트 리뷰 반영 | `agents/code-reviewer` · `security-reviewer` |
| 6 | `/code-quality` 로 게이트를 만들고 CI로 고정 | `commands/code-quality.md` · `.github/workflows` |

---

## 이 데모에서 실제로 일어나는 일

스크립트는 장식을 하지 않습니다. 전부 실제로 실행되고, 전부 실패할 수도 있습니다.

- **3단계** — `npm test` 가 **진짜로** 깨졌다가 통과합니다. 빨간 단계가 없으면 데모가 아닙니다.
- **4단계** — 템플릿의 테스트 훅을 실제로 돌려보고 **종료 코드 0 인 함정**을 확인합니다.
  템플릿 훅은 실패 분기에 `exit` 이 없어서, 화면에 "Tests failed" 가 떠도 Claude Code 는 모릅니다.
- **5단계** — `security-reviewer` 는 `writeFile(filePath)` 에 경로 검증이 없다는
  **실제로 존재하는 결함**을 찾아내고, `mustBeInside()` 로 막은 뒤 테스트로 고정합니다.

단계가 하나라도 기대와 다르면 **그 자리에서 중단**합니다 (`expect` / `expect_fail`).

---

## 만들어지는 앱 (`todo-app/`)

```
todo-app/
├── src/
│   ├── todo-store.js     # 도메인 — add / complete / remove / stats
│   └── persist.js        # JSON 저장 — mustBeInside 로 경로 순회 차단
├── test/
│   └── todo-store.test.js # node:test 10개
├── scripts/
│   ├── review.mjs         # code-reviewer 판정
│   ├── security-audit.mjs # security-reviewer 판정
│   └── quality.mjs        # /code-quality 구현
├── .github/workflows/ci.yml
├── CLAUDE.md
└── .claude/               # 1단계에서 템플릿을 복사한 것
```

에이전트는 역할 정의일 뿐이라, 이 데모에서는 **같은 판정을 하는 검사 스크립트**로 옮겨 담았습니다.
그래서 아무 때나 같은 결과가 재현됩니다.

```bash
cd todo-app
npm test          # 10개 테스트
npm run review    # 정확성·회귀 지적
npm run audit     # 신뢰 경계 점검
npm run quality   # 위 4개를 한 번에
```