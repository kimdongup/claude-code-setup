#!/usr/bin/env bash
# STEP 4 — 하네스 규약 차이를 직접 확인하고 고친다
# 데모 대상: template/grok/.grok/hooks/hook-lib.sh
#
# 이 단계가 Grok 세트에서 제일 중요하다.
# Claude Code 전용 훅은 Grok 에서 "조용히 아무것도 안 하는 훅"이 된다.
source "$(dirname "$0")/../lib.sh"

APP="$DEMO_ROOT/todo-app"
G="$DEMO_ROOT/../../template/grok/.grok"

step_begin 4 hooks "훅이 규칙을 지킨다"

claude "Claude Code 전용으로 만들어진 훅이 Grok 에서도 그대로 동작하는지 확인해줘. stdin 으로 파일 경로를 받는 방식이면 그대로 가야 한다."

note "훅은 실행되어야 의미가 있다. 여기서는 문서를 읽는 게 아니라"
note "두 하네스의 입력을 흉내 내서 실제로 실행해 본다."

# ─────────────────────────────────────────────────────────────
section "1) Claude Code 전용 훅을 Grok 규약으로 돌려본다"

CLAUDE_HOOK='if [[ "${CLAUDE_TOOL_INPUT_FILE_PATH:-}" =~ \.test\.js$ ]]; then
  echo '"'"'{"feedback": "Running tests..."}'"'"' >&2
  echo '"'"'{"feedback": "Tests passed."}'"'"'
fi'

printf '%s\n' "$CLAUDE_HOOK" > "$DEMO_ROOT/logs/claude-style-hook.sh"

note '이 훅은 $CLAUDE_TOOL_INPUT_FILE_PATH 만 본다. (Claude Code 규약)'
note ""
run "Claude Code 규약으로 실행" -- \
  bash -c "CLAUDE_TOOL_INPUT_FILE_PATH='$APP/test/todo-store.test.js' bash '$DEMO_ROOT/logs/claude-style-hook.sh'"

run "Grok 규약으로 실행 (같은 훅)" -- \
  bash -c "printf '%s' '{\"hookEventName\":\"PostToolUse\",\"toolInput\":{\"file_path\":\"$APP/test/todo-store.test.js\"}}' \
           | GROK_HOOK_EVENT=PostToolUse GROK_HOOK_NAME=h1 GROK_WORKSPACE_ROOT='$APP' \
             bash '$DEMO_ROOT/logs/claude-style-hook.sh'; echo \"훅 종료 코드: \$?\""

note ""
note "두 번째 실행은 아무것도 안 했다. 종료 코드 0, 출력 없음."
note "에러가 안 나기 때문에 '훅이 없다'고조차 알아채기 어렵다."
note "이게 이 세트를 만들면서 고친 제1의 문제다."

# ─────────────────────────────────────────────────────────────
section "2) 이식 가능한 헬퍼 (hook-lib.sh) 로 다시 돌린다"

LIB="$G/hooks/hook-lib.sh"
[ -r "$LIB" ] || { echo "hook-lib.sh 없음"; exit 1; }

note "hook-lib.sh 의 tool_input 은 두 하네스를 한 인터페이스로 접는다:"
sed -n '/^tool_input()/,/^}/p' "$LIB" | sed 's/^/  /' | tee -a "$LOG"

PORTABLE_HOOK='#!/usr/bin/env bash
set -uo pipefail
LIB="$(cd "$(dirname "$0")" && pwd)/hook-lib.sh"
. "$LIB"
file="$(tool_input file_path)"
case "$file" in
  *.test.js) echo "{\"feedback\":\"Running tests...\",\"file\":\"$file\"}" ;;
  *)         echo "{\"feedback\":\"no match\",\"file\":\"$file\"}" ;;
esac'

printf '%s\n' "$PORTABLE_HOOK" > "$G/hooks/_probe.sh"
chmod +x "$G/hooks/_probe.sh"

note ""
run "Claude Code 규약" -- \
  bash -c "CLAUDE_TOOL_INPUT_FILE_PATH='$APP/test/todo-store.test.js' bash '$G/hooks/_probe.sh'"

run "Grok 규약 (stdin JSON)" -- \
  bash -c "printf '%s' '{\"hookEventName\":\"PostToolUse\",\"toolInput\":{\"file_path\":\"$APP/test/todo-store.test.js\"}}' \
           | GROK_HOOK_EVENT=PostToolUse GROK_WORKSPACE_ROOT='$APP' bash '$G/hooks/_probe.sh'"

rm -f "$G/hooks/_probe.sh"

note ""
note "같은 훅이 양쪽에서 같은 결과를 냈다. 환경변수도 stdin 도 필요 없다."

# ─────────────────────────────────────────────────────────────
section "3) 차단 프로토콜 — 사유를 두 형식으로"

CLAUDE_DENY='[ "$(git branch --show-current)" != "main" ] || { echo '"'"'{"block": true, "message": "main 브랜치에서 편집할 수 없습니다."}'"'"' >&2; exit 2; }'
GROK_DENY='[ "$(git branch --show-current)" != "main" ] || { printf '"'"'{"decision":"deny","reason":%s}\n'"'"' "$(json_str "main 브랜치에서 편집할 수 없습니다. 먼저 feature 브랜치를 만드세요.")"; exit 2; }'

cd "$APP" && git checkout -q main

note "── Claude Code 훅 (stderr) ──"
run "실행" -- bash -c "$CLAUDE_DENY; echo \"종료 코드: \$?\""
note "Grok 는 stdout 만 읽는다 → 종료 코드는 2 로 차단되지만 사유를 본 사용자는 없다."

note ""
note "── 이식 가능한 deny() (stdout) ──"
G2DENY="$G/hooks/10-pre-tool-use-branch-guard.sh"
run "실행" -- \
  bash -c "printf '%s' '{\"hookEventName\":\"PreToolUse\",\"toolInput\":{\"file_path\":\"$APP/src/todo-store.js\"}}' \
           | GROK_HOOK_EVENT=PreToolUse GROK_WORKSPACE_ROOT='$APP' bash '$G2DENY'; echo \"종료 코드: \$?\""

note ""
note "차단되며 사유도 stdout(json)·stderr 로 동시에 나간다."

note ""
note "── feature 브랜치에서는 통과해야 한다 ──"
cd "$APP"
git checkout -q main
git checkout -q -B feat/todo-branch   # 없으면 만들고, 있으면 그 자리로
expect "차단되지 않고 통과" -- \
  bash -c "printf '%s' '{\"hookEventName\":\"PreToolUse\",\"toolInput\":{\"file_path\":\"$APP/src/todo-store.js\"}}' \
           | GROK_HOOK_EVENT=PreToolUse GROK_WORKSPACE_ROOT='$APP' bash '$G2DENY'; echo \"종료 코드: \$?\""

expect "브랜치 상태 확인" -- bash -c "cd '$APP' && git branch --show-current"

# ─────────────────────────────────────────────────────────────
section "4) 실제 훅 전체가 Grok 규약에서 동작하는지"

note "20-post-tool-use-verify.sh 는 package.json 의 test 스크립트를 기준으로"
note "package.json 이나 소스 파일을 만지면 자동 실행된다. 이 훅도 같은 규약으로 돌린다."

cd "$APP"
run ".test.js 를 건드린 경우 (테스트 자동 실행)" -- \
  bash -c "printf '%s' '{\"hookEventName\":\"PostToolUse\",\"toolInput\":{\"file_path\":\"$APP/test/todo-store.test.js\"}}' \
           | GROK_HOOK_EVENT=PostToolUse GROK_WORKSPACE_ROOT='$APP' bash '$G/hooks/20-post-tool-use-verify.sh' 2>&1 | tail -14; echo \"종료 코드: \${PIPESTATUS[0]}\""

note ""
note "위 출력이 없으면 훅이 침묵한 것이다. 여기서는 __ 파일 __ 이 남아야 정상이다."

step_end