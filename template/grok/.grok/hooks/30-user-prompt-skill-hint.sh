#!/usr/bin/env bash
# UserPromptSubmit — 관련 스킬 힌트 주입
#
# 원본(ChrisWiles/claude-code-showcase)의 skill-eval 는 Node.js 판정 엔진으로
# 키워드와 파일 경로를 분석해 스킬을 추천한다. 그 결정 로직은 그대로 쓰되,
# 입력을 하네스 공통 방식으로 읽도록 바꾸었다.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$DIR/hook-lib.sh"
[ -r "$LIB" ] || exit 0
# shellcheck source=/dev/null
. "$LIB"

RULES="$DIR/skill-rules.json"
ENGINE="$DIR/skill-eval.js"
[ -r "$RULES" ] && [ -r "$ENGINE" ] || exit 0
command -v node >/dev/null 2>&1 || exit 0

ROOT="$(workspace_root)"

# 프롬프트는 두 하네스 모두 stdin JSON 의 .prompt 로 준다.
prompt=""
if [ -n "${GROK_HOOK_EVENT:-}" ]; then
  prompt="$(node -e '
let b="";
process.stdin.on("data",d=>b+=d);
process.stdin.on("end",()=>{try{const j=JSON.parse(b);
  process.stdout.write(j.prompt ?? j.user_prompt ?? j.toolInput?.prompt ?? "");}catch{}});
' 2>/dev/null)"
else
  prompt="${CLAUDE_USER_PROMPT:-}"
fi

node "$ENGINE" --rules "$RULES" --cwd "$ROOT" <<<"$prompt" 2>/dev/null
exit 0