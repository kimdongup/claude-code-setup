#!/usr/bin/env bash
# 할 일 앱 데모 전체 실행기  (macOS 기본 bash 3.2 호환)
#
#   ./example/run-demo.sh          # 처음부터 끝까지 (기존 결과 삭제)
#   ./example/run-demo.sh --keep   # 기존 todo-app 을 남기고 단계만 재실행
#   ./example/run-demo.sh 3 5      # 3~5단계만
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
export DEMO_ROOT="$HERE"
export NO_COLOR="${NO_COLOR:-1}"

KEEP=0
START=""; END=""
for a in "$@"; do
  case "$a" in
    --keep) KEEP=1 ;;
    *) if [ -z "$START" ]; then START="$a"; else END="$a"; fi ;;
  esac
done

if [ "$KEEP" -eq 0 ]; then
  rm -rf "$HERE/todo-app" "$HERE/logs"
fi
mkdir -p "$HERE/logs" "$HERE/todo-app"

B=$'\033[1m'; C=$'\033[36m'; G=$'\033[32m'; R=$'\033[31m'; N=$'\033[0m'; D=$'\033[2m'

printf '\n%s╔══════════════════════════════════════════════════════╗%s\n' "$B$C" "$N"
printf '%s║   Claude Code 템플릿 × 할 일 앱 데모                    ║%s\n' "$B$C" "$N"
printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$B$C" "$N"

[ -z "$START" ] && START=1
idx=0; fails=0

for s in "$HERE"/steps/*.sh; do
  [ -e "$s" ] || continue
  idx=$((idx + 1))
  [ "$idx" -lt "$START" ] && continue
  if [ -n "$END" ] && [ "$idx" -gt "$END" ]; then break; fi

  bash "$s"
  if [ $? -ne 0 ]; then
    fails=$((fails + 1))
    printf '%s✘ STEP %s 실패 — %s%s\n\n' "$B$R" "$idx" "$(basename "$s")" "$N"
  fi
done

printf '%s%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$B$G" "$N"
if [ "$fails" -eq 0 ]; then
  printf '%s✔ 전체 %s단계 통과%s\n' "$B$G" "$idx" "$N"
else
  printf '%s✘ %s단계 실패%s\n' "$B$R" "$fails" "$N"
fi
printf '%s   로그: example/logs/%s\n' "$D" "$N"

printf '\n%s스크린샷 HTML 생성 중…%s\n' "$D" "$N"
if python3 "$HERE/make-walkthrough.py"; then
  printf '%s✔ example/walkthrough.html 생성 완료%s\n\n' "$B$G" "$N"
else
  printf '%s✘ walkthrough 생성 실패%s\n\n' "$B$R" "$N"
fi

printf '%s열어보기:%s open example/walkthrough.html\n\n' "$B" "$N"
[ "$fails" -eq 0 ] && exit 0 || exit 1