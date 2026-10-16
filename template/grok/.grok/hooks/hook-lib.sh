#!/usr/bin/env bash
# hook-lib.sh — 하네스 공통 훅 헬퍼
#
# Claude Code 와 Grok Build 는 훅에 같은 정보를 주지만 **채워우는 방식이 다르다**.
#   Claude Code : $CLAUDE_TOOL_INPUT_FILE_PATH 환경변수
#   Grok Build  : stdin 으로 JSON (toolInput.file_path)
# 아래 함수들은 그 차이를 숨기고 동일한 인터페이스를 제공한다.

# ─────────────────────────────────────────────────────────────
# tool_input <필드>
#   현재 훅 이벤트의 도구 입력 필드 값을 stdout 으로 돌려준다.
#   값이 없으면 빈 문자열.
# ─────────────────────────────────────────────────────────────
tool_input() {
  local key="${1:-}" val=""

  # 1순위: 하네스가 직접 준 환경변수 (stdin 소비 없이 끝난다)
  case "$key" in
    file_path)
      [ -n "${CLAUDE_TOOL_INPUT_FILE_PATH:-}" ] && { printf '%s' "$CLAUDE_TOOL_INPUT_FILE_PATH"; return 0; }
      [ -n "${GROK_TOOL_INPUT_FILE_PATH:-}" ]  && { printf '%s' "$GROK_TOOL_INPUT_FILE_PATH";  return 0; }
      ;;
  esac

  # 2순위: Grok Build — stdin JSON 파싱
  # 이 하네스일 때만 시도한다. Claude Code 에서 stdin 은 비어 있으므로 비용이 없다.
  [ -n "${GROK_HOOK_EVENT:-}" ] || return 0

  val="$(node -e '
let buf = "";
process.stdin.on("data", (d) => (buf += d));
process.stdin.on("end", () => {
  try {
    const j = JSON.parse(buf);
    const ti = j.toolInput ?? j.tool_input ?? {};
    const raw = ti[process.argv[1]];
    process.stdout.write(raw === undefined || raw === null ? "" : String(raw));
  } catch { /* 조용히 무시 — 훅은 절대 예외를 던지지 않는다 */ }
});
' "$key" 2>/dev/null)"

  printf '%s' "$val"
}

# ─────────────────────────────────────────────────────────────
# workspace_root — 프로젝트 루트 경로
# ─────────────────────────────────────────────────────────────
workspace_root() {
  [ -n "${CLAUDE_PROJECT_DIR:-}" ]   && { printf '%s' "$CLAUDE_PROJECT_DIR";  return 0; }
  [ -n "${GROK_WORKSPACE_ROOT:-}" ]  && { printf '%s' "$GROK_WORKSPACE_ROOT"; return 0; }
  git rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD"
}

# ─────────────────────────────────────────────────────────────
# deny <사유> — PreToolUse 전용 도구 호출 차단
#
# 두 하네스가 서로 다른 형식을 쓴다. 둘 다 만족시키려면
# stdout(Grok) 과 stderr(Claude) 에 각각 형식에 맞춰 출력한다.
#   Claude Code : stderr {"block": true, "message": "..."} + exit 2
#   Grok Build  : stdout {"decision": "deny", "reason": "..."} + exit 2
# 어느 쪽이든 exit 2 는 차단이다.
# ─────────────────────────────────────────────────────────────
deny() {
  local reason="$1"
  printf '{"decision":"deny","reason":%s}\n' "$(json_str "$reason")"
  printf '{"block": true, "message":%s}\n' "$(json_str "$reason")" >&2
  exit 2
}

# json_str <문자열> — JSON 문자열 리터럴로 이스케이프
json_str() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1" 2>/dev/null \
    || printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}

# feedback <메시지> [성공|실패] — 하네스에 알림 (표시 전용, 차단 아님)
feedback() {
  printf '{"feedback":%s}\n' "$(json_str "$1")"
}