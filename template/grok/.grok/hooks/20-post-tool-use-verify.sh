#!/usr/bin/env bash
# PostToolUse — 편집된 파일 종류에 따라 자동 정리/검증
#
# Claude Code 전용 환경변수를 쓰지 않고 하네스 공통 인터페이스(tool_input)만 쓴다.
# 따라서 .claude/settings.json 에 그대로 넣어도, .grok/hooks/*.json 으로 넣어도 동작한다.
set -uo pipefail
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hook-lib.sh"
[ -r "$LIB" ] || exit 0
# shellcheck source=/dev/null
. "$LIB"

ROOT="$(workspace_root)"
file="$(tool_input file_path)"
[ -n "$file" ] || exit 0
cd "$ROOT" 2>/dev/null || exit 0

run() { timeout "${HOOK_TIMEOUT:-90}" "$@" 2>&1; }

# ── 1. 테스트 파일을 건드렸으면 관련 테스트 자동 실행 ──────────
case "$file" in
  *.test.js|*.test.jsx|*.test.ts|*.test.tsx|*.spec.js|*.spec.ts)
    feedback "변경된 테스트를 실행합니다…" >&2
    out="$(run npm test --silent)"; rc=$?
    printf '%s\n' "$out" | tail -20
    if [ $rc -eq 0 ]; then
      feedback "테스트 통과"
      exit 0
    fi
    feedback "테스트 실패 — 이어가기 전에 고치세요" >&2
    exit 1
    ;;
esac

# ── 2. 의존성 목록이 바뀌었으면 설치 ───────────────────────────
case "$file" in
  *package.json)
    feedback "의존성을 설치합니다…" >&2
    if run npm install >/dev/null; then
      feedback "의존성 설치 완료" >/dev/null
    else
      feedback "의존성 설치 실패" >&2
      exit 1
    fi
    exit 0
    ;;
esac

# ── 3. TypeScript 를 건드렸으면 타입 검사 ──────────────────────
case "$file" in
  *.ts|*.tsx)
    if [ -f package.json ] && grep -q '"typecheck"' package.json 2>/dev/null; then
      feedback "타입을 검사합니다…" >&2
      out="$(run npm run typecheck)"; rc=$?
      if [ $rc -ne 0 ]; then
        printf '%s\n' "$out" | grep -E "error TS" | head -20 >&2
        feedback "타입 오류가 있습니다" >&2
        exit 1
      fi
      feedback "타입 검사 통과" >/dev/null
    fi
    ;;
esac

# ── 4. 소스 파일을 건드렸으면 포맷 (포맷터가 있을 때만) ─────────
case "$file" in
  *.js|*.jsx|*.ts|*.tsx)
    [ -f package.json ] || exit 0
    if grep -qE '"format"\s*:' package.json 2>/dev/null; then
      feedback "포맷합니다…" >&2
      run npm run format >/dev/null || { feedback "포맷 실패 — 문법 오류가 있을 수 있습니다" >&2; exit 1; }
      feedback "포맷 완료" >/dev/null
    fi
    ;;
esac

exit 0