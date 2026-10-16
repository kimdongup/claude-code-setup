#!/usr/bin/env bash
# 공용 헬퍼: 터미널 표시 + 로그 캡처
# 모든 단계 스크립트가 이 파일을 source 한다.

set -uo pipefail

: "${DEMO_ROOT:?DEMO_ROOT must be set before sourcing lib.sh}"
LOG_DIR="$DEMO_ROOT/logs"
mkdir -p "$LOG_DIR"

# ANSI (터미널이 아닌 경우 자동으로 무시됨)
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
  B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
  CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BLUE=$'\033[34m'
else
  B=''; D=''; R=''; CYAN=''; GREEN=''; YELLOW=''; RED=''; BLUE=''
fi

STEP_NO=""
STEP_SLUG=""

# 문자 단위 정확 래핑 (한글·이모지 안전 — fold 는 바이트를 세어서 깨진다)
# wrap <너비> <문자열> → 래핑된 줄을 stdout 으로
wrap() {
  local width="$1"; shift
  python3 -c '
import sys, textwrap
w = int(sys.argv[1])
for para in " ".join(sys.argv[2:]).split("\n"):
    if not para.strip():
        print("")
        continue
    for l in textwrap.wrap(para, width=w, break_long_words=False,
                           break_on_hyphens=False, replace_whitespace=False) or [""]:
        print(l)
' "$width" "$@"
}

# wrap_into <너비> <접두어> <문자열...> → 래핑 결과를 stdout. 필요하면 tee 로 로그에 남긴다.
wrap_into() {
  local width="$1" prefix="$2"; shift 2
  wrap "$width" "$@" | while IFS= read -r l; do printf '%s%s\n' "$prefix" "$l"; done
}

# step_begin <번호> <슬러그> <제목>
step_begin() {
  STEP_NO="$1"; STEP_SLUG="$2"
  TITLE="$3"
  LOG="$LOG_DIR/${STEP_NO}-${STEP_SLUG}.log"
  : > "$LOG"
  {
    printf '%s\n' "$B${CYAN}━━━ STEP ${STEP_NO} ━━━${R} ${B}${TITLE}${R}"
    printf '%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '\n'
  } | tee -a "$LOG"
}

# section <텍스트>
section() {
  printf '\n%s▸ %s%s\n' "$B$BLUE" "$1" "$R" | tee -a "$LOG"
}

# claude <프롬프트>  — Claude Code에 입력할 자연어 명령
claude() {
  local body
  body="$(wrap 84 "$1" | sed 's/^/│ /')"
  {
    printf '\n%s╭─ Claude Code 에 입력한 프롬프트%s\n' "$B$YELLOW" "$R"
    printf '%s\n' "$body"
    printf '%s╰%s%s\n' "$YELLOW" "$(printf '─%.0s' $(seq 1 60))" "$R"
  } | tee -a "$LOG"
}

# run <설명> -- <실행할 명령...>
run() {
  local desc="$1"; shift
  case "${1:-}" in --) shift ;; esac
  printf '\n%s$%s %s%s\n' "$B$GREEN" "$R" "$D$desc$R" | tee -a "$LOG"
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  printf '%s\n' "$out" | sed 's/^/  /' | tee -a "$LOG" >/dev/null
  printf '%s\n' "$out" | sed 's/^/  /'
  if [ $rc -ne 0 ]; then
    printf '%s(종료 코드 %s)%s\n' "$D" "$rc" "$R" | tee -a "$LOG"
  fi
  return $rc
}

# expect <설명> -- <실행할 명령...>  : 반드시 성공해야 하는 단계. 실패 시 단계 중단.
expect() {
  local desc="$1"; shift
  case "${1:-}" in --) shift ;; esac
  if run "$desc" "$@"; then
    printf '%s✔ 기대한 결과%s\n' "$B$GREEN" "$R" | tee -a "$LOG"
    return 0
  fi
  printf '%s✘ 실패 — 단계를 중단합니다%s\n' "$B$RED" "$R" | tee -a "$LOG" >&2
  exit 1
}

# expect_fail <설명> -- <실행할 명령...> : 반드시 실패해야 하는 단계(훅 시연용)
expect_fail() {
  local desc="$1"; shift
  case "${1:-}" in --) shift ;; esac
  printf '\n%s$%s %s%s\n' "$B$GREEN" "$R" "$D$desc$R" | tee -a "$LOG"
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  printf '%s\n' "$out" | sed 's/^/  /' | tee -a "$LOG" >/dev/null
  printf '%s\n' "$out" | sed 's/^/  /'
  if [ $rc -ne 0 ]; then
    printf '%s✔ 의도대로 실패함 (종료 코드 %s)%s\n' "$B$GREEN" "$rc" "$R" | tee -a "$LOG"
    return 0
  fi
  printf '%s✘ 실패할 줄 알았는데 성공했습니다 — 단계를 중단합니다%s\n' "$B$RED" "$R" | tee -a "$LOG" >&2
  exit 1
}

# note <텍스트>
note() {
  wrap_into 94 "  → " "$1" | tee -a "$LOG"
}

# table <헤더...> -- <행...>   (배열 없이 동작 — macOS bash 3.2 호환)
table() {
  local hdr="" sep="" a
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do
    hdr="$hdr$(printf '%-18s' "$1")"
    sep="$sep"
    shift
  done
  [ $# -gt 0 ] && shift
  {
    printf '\n  %b%s%b\n' "$B" "${hdr% }" "$R"
    for a in "$@"; do printf '  %s\n' "$a"; done
    printf '\n'
  } | tee -a "$LOG"
}

step_end() {
  printf '\n%s✔ STEP %s 완료 — 로그: example/logs/%s%s\n\n' \
    "$B$GREEN" "$STEP_NO" "$(basename "$LOG")" "$R"
}

# 템플릿 파일의 특정 훅 명령을 그대로 추출해 실행한다(설정이 실제로 쓰이는지 증명)
hook_from_template() {
  # hook_from_template <settings.json의 hooks 경로>
  python3 - "$DEMO_ROOT/../../template/claude/.claude/settings.json" "$1" <<'PY'
import json, sys, os
p, path = sys.argv[1], sys.argv[2]
hooks = json.load(open(p)).get("hooks", {})
for matcher, entries in hooks.items():
    for e in entries:
        for h in e.get("hooks", []):
            cmd = h.get("command", "")
            if path in cmd:
                print(cmd)
                sys.exit(0)
sys.exit(1)
PY
}