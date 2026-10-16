#!/usr/bin/env bash
# STEP 6 — 슬래시 명령 + CI 게이트 + 커밋
# 데모 대상: template/.claude/commands/code-quality.md, template/.github/workflows/
source "$(dirname "$0")/../lib.sh"

APP="$DEMO_ROOT/todo-app"
TPL="$DEMO_ROOT/../template"

step_begin 6 quality "명령으로 돌리고 CI로 지킨다"

claude "/code-quality src

그리고 이 결과가 CI에서 막히게 만들어줘. PR 올라오면 테스트·리뷰·의존성 감사가 자동으로 돌게."

# ---------------------------------------------------------------- /code-quality
section "1) /code-quality 명령 실행"

cat > "$APP/scripts/quality.mjs" <<'Q'
import { spawnSync } from 'node:child_process';

const run = (label, cmd, args) => {
  process.stdout.write(`\n▸ ${label}\n$ ${cmd} ${args.join(' ')}\n`);
  // npm 이 설정으로 주입하는 npm_config_* 를 걷어낸다 — 안 그러면
  // `npm run` 안에서 중첩된 `npm audit` 가 스스로를 끄고 0 이 아닌 값을 준다.
  const env = { ...process.env };
  for (const k of Object.keys(env)) if (k.startsWith('npm_config_')) delete env[k];
  const r = spawnSync(cmd, args, { encoding: 'utf8', env, stdio: ['ignore', 'pipe', 'pipe'] });
  process.stdout.write((r.stdout || '') + (r.stderr || ''));
  if (r.status !== 0) {
    process.stdout.write(`  (종료 코드 ${r.status})\n`);
  }
  return { label, ok: r.status === 0 };
};

const results = [
  ['테스트',       'npm', ['test', '--silent']],
  ['코드 리뷰',    'npm', ['run', 'review', '--silent']],
  ['보안 감사',    'npm', ['run', 'audit', '--silent']],
  ['의존성 감사',  'npm', ['audit', '--omit=dev', '--audit-level=high']],
];

let failed = [];
for (const [label, cmd, args] of results) {
  const r = run(label, cmd, args);
  if (!r.ok) failed.push(r.label);
}

console.log(`\n${'─'.repeat(56)}`);
if (failed.length) {
  console.log(`code-quality: ${failed.length}개 검사 실패 ❌  — ${failed.join(', ')}`);
  process.exit(1);
}
console.log(`code-quality: ${results.length}개 검사 모두 통과 ✅`);
Q

expect "npm run quality" -- env -C "$APP" npm run quality --silent

# ---------------------------------------------------------------- CI
section "2) GitHub Actions CI 게이트"

mkdir -p "$APP/.github/workflows"

cat > "$APP/.github/workflows/ci.yml" <<'YML'
name: ci
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: 테스트
        run: npm test

      - name: 코드 리뷰 규칙
        run: npm run review

      - name: 보안 감사
        run: npm run audit

      - name: 의존성 감사
        run: npm audit --audit-level=high
YML

note "설정 파일이 아니라 실제 워크플로가 되려면 이것이 필요하다."
note "로컬에서 CI와 같은 순서를 그대로 돌려 확인한다:"

run "CI 파이프라인 재현 (테스트 → 리뷰 → 보안 → 의존성)" -- \
  bash -c "cd '$APP' \
    && npm test --silent >/dev/null 2>&1 && echo '  테스트      ✅' \
    && npm run review --silent >/dev/null 2>&1 && echo '  코드 리뷰   ✅' \
    && npm run audit --silent  >/dev/null 2>&1 && echo '  보안 감사   ✅' \
    && npm audit --omit=dev --audit-level=high >/dev/null 2>&1 && echo '  의존성 감사 ✅' \
    && echo && echo '  PR 병합 가능'"

# ---------------------------------------------------------------- 커밋
section "3) 커밋 — Co-Authored-By 는 설정에서 온다"

run "settings.json 의 includeCoAuthoredBy" -- \
  python3 -c "import json;print(json.load(open('$APP/.claude/settings.json'))['includeCoAuthoredBy'])"

cd "$APP"
expect "git add -A" -- git add -A
expect "git commit" -- \
  env GIT_AUTHOR_NAME=demo GIT_AUTHOR_EMAIL=demo@example.com \
      GIT_COMMITTER_NAME=demo GIT_COMMITTER_EMAIL=demo@example.com \
      git commit -q -F - <<'MSG'
feat: 할 일 도메인 TDD 구현 + 경로 순회 방어

- testing-patterns 스킬로 red → green → refactor 3회 진행
- code-reviewer 지적(중복 반환)을 반영해 mustFind/snapshot 분리
- security-reviewer 지적(경로 순회)을 mustBeInside 로 차단
- Jest 전용 훅을 node:test 용으로 수정
MSG

section "결과"
run "커밋 내역" -- git log --oneline
run "소스 변경 내역 (.claude 제외)" -- \
  git show --stat --format= HEAD -- src test scripts package.json .github

table \
  "단계" "사용한 템플릿 요소" \
  -- \
  "1 부트스트랩      settings.json (훅 목록 확인)" \
  "2 메모리          CLAUDE.md 구조" \
  "3 TDD             skills/testing-patterns/SKILL.md" \
  "4 훅              settings.json PreToolUse·PostToolUse" \
  "5 서브에이전트    agents/code-reviewer.md·security-reviewer.md" \
  "6 명령·CI         commands/code-quality.md·.github/workflows"

step_end