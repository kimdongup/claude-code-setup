#!/usr/bin/env bash
# STEP 4 — 훅이 규칙을 지킨다 (설정 파일이 실제로 동작하는지 증명)
# 데모 대상: template/claude/.claude/settings.json 의 PreToolUse / PostToolUse
source "$(dirname "$0")/../lib.sh"

APP="$DEMO_ROOT/todo-app"
S="$DEMO_ROOT/../../template/claude/.claude/settings.json"

step_begin 4 hooks "훅이 규칙을 지킨다"

claude "설정에 들어 있는 훅이 정말 동작하는지 확인해줘. main 브랜치에서 파일을 고려고 하면 막히는지, 테스트 파일을 건드리면 테스트가 자동으로 도는지 확인해서 이 프로젝트에 맞게 고쳐줘."

note "훅은 Claude Code가 파일을 고치기 전후에 알아서 실행한다. 여기서는 템플릿에 들어 있는 훅 명령을 그대로 꺼내 같은 환경변수를 주입해 실행한다."

# --------------------------------------------------------- PreToolUse: 차단
section "1) PreToolUse — main 브랜치 편집 차단"

HOOK_PRE="$(hook_from_template 'Prevent editing on main branch')"
note "템플릿 훅 명령:"
printf '  %s\n' "$HOOK_PRE" | fold -s -w 86 | sed '2,$s/^/  /' | tee -a "$LOG"

note ""
note "① main 브랜치에서 편집 시도"

cd "$APP" && git checkout -q main
expect_fail "Write 도구 훅이 실행됨" -- \
  env CLAUDE_PROJECT_DIR="$APP" CLAUDE_TOOL_INPUT_FILE_PATH="$APP/src/todo-store.js" \
  bash -c "$HOOK_PRE"

note "② feature 브랜치로 바꾸면 통과한다"
git checkout -q -b feat/todo-domain
expect "Write 도구 훅이 통과시킴" -- \
  env CLAUDE_PROJECT_DIR="$APP" CLAUDE_TOOL_INPUT_FILE_PATH="$APP/src/todo-store.js" \
  bash -c "$HOOK_PRE"

# --------------------------------------------------------- PostToolUse: 자동 테스트
section "2) PostToolUse — 테스트 파일을 건드리면 자동 실행"

HOOK_POST="$(hook_from_template 'Auto-run tests when test files change')"
note "템플릿 훅 명령:"
printf '  %s\n' "$HOOK_POST" | fold -s -w 86 | sed '2,$s/^/  /' | tee -a "$LOG"

note ""
note "그대로 실행해 본다 (이 프로젝트는 node:test 를 쓴다)"
touch "$APP/test/todo-store.test.js"

printf '%s\n' "$HOOK_POST" > "$DEMO_ROOT/logs/hook-postuse.hook"
run "PostToolUse 훅을 그대로 돌리고 종료 코드를 본다" -- \
  bash -c "cd '$APP' && CLAUDE_PROJECT_DIR='$APP' CLAUDE_TOOL_INPUT_FILE_PATH='$APP/test/todo-store.test.js' bash '$DEMO_ROOT/logs/hook-postuse.hook'; echo \"훅 종료 코드: \$?\""

note ""
note "여기서 진짜 함정이 하나 더 있다."
note "'Tests failed' 가 출력됐는데 종료 코드는 0 이었다."
note "훅의 실패 분기에 exit 이 없어서, Claude Code 는 테스트가 깨졌다는"
note "사실을 전혀 전달받지 못하고 그대로 다음 단계로 넘어간다."

# --------------------------------------------------------- 훅을 프로젝트에 맞게 수정
section "3) 훅을 이 프로젝트에 맞게 고친다"

python3 - "$APP/.claude/settings.json" <<'PY'
import json, sys
p = sys.argv[1]
cfg = json.load(open(p))

for entry in cfg["hooks"].get("PostToolUse", []):
    for h in entry.get("hooks", []):
        cmd = h.get("command", "")

        # 1) 테스트 훅: Jest 전용 플래그 제거 + 실패 시 반드시 exit 1
        if "Auto-run tests when test files change" in cmd:
            h["command"] = (
                '# Auto-run tests when test files change (node:test)\n'
                'if [[ "$CLAUDE_TOOL_INPUT_FILE_PATH" =~ \\.test\\.js$ ]]; then\n'
                '  echo \'{"feedback": "Running tests..."}\' >&2\n'
                '  out=$(npm test --silent 2>&1); rc=$?\n'
                '  echo "$out" | tail -12\n'
                '  if [ $rc -eq 0 ]; then\n'
                '    echo \'{"feedback": "Tests passed."}\'\n'
                '    exit 0\n'
                '  fi\n'
                '  # 여기서 exit 이 없으면 훅이 0 을 반환해 Claude Code 가 실패를 모른다.\n'
                '  echo \'{"feedback": "Tests failed. 고치고 이어가세요."}\' >&2\n'
                '  exit 1\n'
                'fi'
            )

        # 2) 포맷 훅: 의존성 0개 원칙이라 끈다
        if "Prettier" in cmd:
            h["command"] = (
                '# 이 프로젝트는 외부 의존성 0개이므로 자동 포맷 훅을 끈다\n'
                'true'
            )

        # 3) 의존성 자동 설치: node:test 는 설치할 것이 없다
        if "Auto-install dependencies" in cmd:
            h["command"] = (
                '# 의존성이 0개라 설치할 것이 없다. package.json 이 바뀌면 알린다.\n'
                'echo \'{"feedback": "package.json 변경됨 — 의존성 0개 규칙 확인", "suppressOutput": true}\''
            )

json.dump(cfg, open(p, "w"), ensure_ascii=False, indent=2)
open(p, "a").write("\n")
print("hooks patched for node:test")
PY

node5() {
  python3 - "$APP/.claude/settings.json" <<'PY'
import json, sys
for e in json.load(open(sys.argv[1]))["hooks"]["PostToolUse"]:
    for h in e["hooks"]:
        if "node:test" in h["command"]:
            print(h["command"]); sys.exit(0)
sys.exit(1)
PY
}

note ""
note "고친 뒤 다시 실행 — 이번엔 테스트가 통과한다"
expect "통과: 훅이 0 을 반환" -- \
  env CLAUDE_PROJECT_DIR="$APP" CLAUDE_TOOL_INPUT_FILE_PATH="$APP/test/todo-store.test.js" \
  bash -c "$(node5)"

note ""
note "이번에는 일부러 테스트를 깨뜨려 본다"
cp "$APP/src/todo-store.js" "$APP/src/todo-store.js.bak"
printf '\n// 실수로 추가한 버그\nexport const broken = null;\n' >> "$APP/src/todo-store.js"
cat >> "$APP/test/todo-store.test.js" <<'TB'

test('의도적으로 깨뜨린 테스트', () => {
  assert.equal(createStore().list().length, 99);
});
TB

expect_fail "깨진 테스트를 감지해 훅이 1 을 반환" -- \
  env CLAUDE_PROJECT_DIR="$APP" CLAUDE_TOOL_INPUT_FILE_PATH="$APP/test/todo-store.test.js" \
  bash -c "$(node5)"

mv "$APP/src/todo-store.js.bak" "$APP/src/todo-store.js"
python3 - "$APP/test/todo-store.test.js" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
s = s.split("\ntest('의도적으로 깨뜨린 테스트'")[0].rstrip() + "\n"
open(p, "w", encoding='utf-8').write(s)
PY

note "훅을 고치지 않으면 Claude Code 는 깨진 테스트를 모른 채 다음 단계로 넘어간다."

step_end