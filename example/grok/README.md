# example/grok/

`template/grok/` 을 **Grok Build 규약으로** 실제로 굴려 보는 6단계 기록입니다.
[`../claude/`](../claude/) 와 같은 6단계를 두 하네스에서 돌린 결과를 비교할 수 있습니다.
**이 폴더의 스크립트를 실행하면 `todo-app/` 이 새로 만들어집니다.** (결과물은 `.gitignore` 대상)

```bash
./run-demo.sh          # 처음부터 6단계 실행 + walkthrough.html 갱신
./run-demo.sh --keep   # 만들어진 앱을 남기고 단계만 다시 실행
open walkthrough.html  # 스크린샷이 담긴 가이드 열기
```

요구 환경: `bash`, `node` 20+, `python3`, `git`.
`grok` CLI([설치](https://docs.x.ai/build))가 있으면 1단계에서 **실제 인식 확인**을 추가로 합니다.

---

## claude 데모와 무엇이 다른가

| 단계 | claaude 세트 | grok 세트 |
|---|---|---|
| 1 | 템플릿 적용 | 템플릿 적용 + **`grok --trust inspect` 로 실제 로드 확인** |
| 2 | `CLAUDE.md` 작성 | `AGENTS.md` 작성 |
| 3 | TDD | TDD (동일) |
| 4 | 훅이 함정을 조용히 삼킨다 | **두 하네스 규약 차이를 직접 실행해 비교** |
| 5 | 서브에이전트 리뷰 | 서브에이전트 리뷰 (동일) |
| 6 | `/code-quality` + CI | `/code-quality` + CI (동일) |

**4단계가 이 세트의 존재 이유입니다.**

```
── Claude Code 규약으로 실행 ──
{"feedback": "Running tests..."}     ← 동작

── Grok 규약으로 실행 (같은 훅) ──
훅 종료 코드: 0                      ← 아무것도 안 함
```

에러가 나지 않기 때문에 "훅이 없다"는 사실조차 알아채기 어렵습니다.
`hook-lib.sh` 로 고친 뒤에는 양쪽에서 같은 결과가 나옵니다.

---

## 결과물

| 경로 | 내용 | git |
|---|---|---|
| `walkthrough.html` | 단계별 스크린샷 + 설명 (단일 파일, 외부 자원 없음) | ✅ 커밋 |
| `steps/*.sh` | 6개 단계 스크립트 | ✅ 커밋 |
| `run-demo.sh` · `lib.sh` · `make-walkthrough.py` | 실행 인프라 | ✅ 커밋 |
| `todo-app/` | 실행 결과 | ❌ 무시 |
| `logs/` | 실행 로그 (스크린샷 원본) | ❌ 무시 |

---

## 만들어지는 앱

`../claude/` 와 같은 앱입니다 (`src/` `test/` `scripts/` 동일).
다른 건 어느 쪽 하네스에서 만들었는지뿐입니다.

```bash
cd todo-app
npm test          # 10개 테스트
npm run review    # 정확성·회귀 지적
npm run audit     # 신뢰 경계 점검
npm run quality   # 위 4개를 한 번에
```

> 이 앱의 품질 게이트는 **모델 비의존**입니다.
> Node.js 와 셸로만 돌아서 Claude Code, Grok Build, 모델 없이도 같은 판정을 냅니다.