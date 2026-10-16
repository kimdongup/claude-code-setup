#!/usr/bin/env bash
# PreToolUse — 위험한 편집 차단
#
# hook-lib.sh 의 deny() 가 Claude Code 형식과 Grok Build 형식을 동시에 출력한다.
# 어느 하네스에서 실행해도 동일하게 "차단 + 사유 전달" 이 된다.
set -uo pipefail
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hook-lib.sh"
[ -r "$LIB" ] || exit 0
# shellcheck source=/dev/null
. "$LIB"

[ "${GROK_HOOK_EVENT:-${CLAUDE_HOOK_EVENT:-}}" = "PreToolUse" ] || exit 0

file="$(tool_input file_path)"

# 파일 편집 계열만 막는다. 읽기·탐색은 제한하지 않는다.
case "$file" in
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.py|*.go|*.rs|*.rb|*.java|*.php|*.sh|*.md|*.json|*.yml|*.yaml) ;;
  *) exit 0 ;;
esac

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  deny "main 브랜치에서는 파일을 수정할 수 없습니다. 현재 변경은 되돌리기 어렵습니다.
먼저 feature 브랜치를 만드세요:  git checkout -b feat/설명
그리고 다시 시도하세요."
fi

exit 0