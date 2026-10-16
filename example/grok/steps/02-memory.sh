#!/usr/bin/env bash
# STEP 2 — 프로젝트 메모리(AGENTS.md) 만들기
# 데모 대상: template/grok/AGENTS.md 구조, 템플릿의 스킬/에이전트 목록
source "$(dirname "$0")/../lib.sh"

APP="$DEMO_ROOT/todo-app"

step_begin 2 memory "프로젝트 기억 만들기"

claude "이 프로젝트는 의존성 없이 Node.js 내장 테스트 러너(node:test)만 쓴다. 모든 함수에 JSDoc 주석을 달고, 모듈 경로는 ./src/ 아래로 통일해줘. 테스트는 반드시 함수 하나당 한 가지 행동만 검증하게 해줘. 이 규칙을 AGENTS.md에 기록해줘."

note "기억 파일은 세션마다 자동으로 읽히므로, 매번 프롬프트로 반복할 필요가 없다."

section "Grok 가 작성한 AGENTS.md"

cat > "$APP/AGENTS.md" <<'MEM'
# todo-app 프로젝트 규칙  (AGENTS.md)

## 기술 스택
- Node.js 20+, 외부 의존성 **0개**. 테스트는 `node:test` 내장 러너만 사용.
- ESM 모듈 (`"type": "module"`). 모듈 경로는 항상 `./src/` 하위.

## 코딩 규칙
- 모든 exported 함수에 JSDoc `@param` / `@returns` 주석을 단다.
- 함수 하나는 **하나의 행동**만 한다. 테스트도 그에 1:1로 대응한다.
- 상태를 직접 바꾸지 말고 **불변 갱신**(`{...state, field}`)을 쓴다.
- 에러는 삼키지 않는다. 원인이 없으면 `throw new Error('...')` 로 드러낸다.

## 테스트 규칙
- 테스트 이름은 `test('<조건> → <기대 결과>')` 형식으로 쓴다.
-Arrange → Act → Assert 세 블록을 빈 줄로 구분한다.
- 테스트는 `src/` 를 직접 참조하지 않고 `./<모듈경로>` 로만 진입한다.

## 금지 사항
- `any`, `@ts-ignore`, `// eslint-disable` 로 컴파일러를 속이지 않는다.
- 테스트 없이 프로덕션 코드를 먼저 쓰지 않는다(TDD: red → green → refactor).

## 자주 쓰는 명령
```bash
npm test                 # 전체 테스트
npm run test:watch       # 워치 모드
npm run quality          # quality 게이트 (포맷·테스트·커버리지)
```
MEM

run "작성된 AGENTS.md" -- cat "$APP/AGENTS.md"

section "기억 파일이 프로젝트 루트에 잡히는 이유"
run "AGENTS.md 탐색 경로" -- \
  bash -c "printf '프로젝트 루트\n  └─ AGENTS.md              ← 이 파일 (우선순위 1)\n하위 디렉터리\n  └─ packages/api/AGENTS.md  ← 그 서브트리만 적용\n'; ls -1 '$APP/AGENTS.md'"

section "템플릿이 제공하는 기억 조각"
run "스킬(지식) 상위 8개" -- \
  bash -c "ls -1 '$DEMO_ROOT/../../template/grok/.grok/skills' | head -8"
run "에이전트(역할) 전부" -- \
  bash -c "ls -1 '$DEMO_ROOT/../../template/grok/.grok/agents'"

note "AGENTS.md(기억) · SKILL.md(지식) · agents/*.md(역할) · commands/*.md(명령)"
note "이 4개가 이 템플릿의 핵심 축이다."

step_end