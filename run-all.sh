#!/usr/bin/env bash
# 두 세트(Claude / Grok)의 템플릿 설치와 예시를 한 번에 확인한다.
#
#   ./run-all.sh              두 세트 데모를 모두 실행 + 동기화 검사
#   ./run-all.sh claude       claude 세트만
#   ./run-all.sh grok         grok 세트만
#   ./run-all.sh check        데모 없이 동기화 검사만
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
WHICH="${1:-all}"

B=$'\033[1m'; C=$'\033[36m'; G=$'\033[32m'; R=$'\033[31m'; N=$'\033[0m'; D=$'\033[2m'

if [ "$WHICH" = "check" ]; then
  exec python3 "$ROOT/tools/check-sync.py"
fi

printf '\n%s━━━ 0/2  두 세트 동기화 검사 ━━━%s\n' "$B$C" "$N"
python3 "$ROOT/tools/check-sync.py"
sync_rc=$?
echo

run_one() {
  local name="$1"
  printf '%s━━━ %s ━━━%s\n\n' "$B$C" "$name" "$N"
  "$ROOT/example/$name/run-demo.sh"
  return $?
}

rc=0
[ "$sync_rc" -ne 0 ] && rc=1

if [ "$WHICH" = "all" ] || [ "$WHICH" = "claude" ]; then
  run_one claude || rc=1
fi
if [ "$WHICH" = "all" ] || [ "$WHICH" = "grok" ]; then
  run_one grok || rc=1
fi

printf '\n%s%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$B" "$C" "$N"
if [ "$rc" -eq 0 ]; then
  printf '%s✔ 두 세트 모두 통과%s\n' "$B$G" "$N"
  printf '%s   example/claude/walkthrough.html\n   example/grok/walkthrough.html%s\n\n' "$D" "$N"
else
  printf '%s✘ 실패가 있습니다%s\n\n' "$B$R" "$N"
fi
exit "$rc"