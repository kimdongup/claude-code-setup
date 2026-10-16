#!/usr/bin/env bash
# STEP 1 — 빈 디렉터리에서 프로젝트 시작 + 템플릿 적용
# 데모 대상: template/claude/.claude/settings.json (hooks), template/claude/CLAUDE.md (memory)
source "$(dirname "$0")/../lib.sh"

step_begin 1 bootstrap "빈 폴더에서 시작하기"

APP="$DEMO_ROOT/todo-app"
TPL="$DEMO_ROOT/../../template/claude"

claude "빈 폴더에 Node.js 할 일 앱을 새로 만들자. 먼저 git 저장소를 초기화하고 feature 브랜치에서 시작해줘. main에서 직접 편집하지 않는 규칙을 지키고 싶어."

section "git 저장소 초기화"
expect "git init + 기본 브랜치 이름 main 지정" -- \
  git -C "$APP" init -q -b main

expect "첫 커밋 (빈 트리)" -- \
  git -C "$APP" -c user.email=demo@example.com -c user.name=demo commit -q \
    --allow-empty -m "chore: 프로젝트 시작"

note "이 시점에서 Claude Code의 PreToolUse 훅이 활성화된다."

section "Claude Code 템플릿 적용"
expect "template/claude/.claude → 앱으로 복사" -- \
  cp -R "$TPL/.claude" "$APP/.claude"

note "복사된 항목:"
printf '  agents=%s  commands=%s  hooks=%s  skills=%s\n' \
  "$(find "$APP/.claude/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')" \
  "$(find "$APP/.claude/commands" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')" \
  "$(find "$APP/.claude/hooks" -type f 2>/dev/null | wc -l | tr -d ' ')" \
  "$(find "$APP/.claude/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')" \
  | tee -a "$LOG"

expect "template/claude/CLAUDE.md → 앱 메모리로 복사" -- \
  cp "$TPL/CLAUDE.md" "$APP/CLAUDE.md"

section "설정 파일이 실제로 읽히는지 확인"
run "설정의 훅 정의 개수" -- \
  python3 -c "import json;h=json.load(open('$APP/.claude/settings.json'))['hooks'];print('\n'.join(f'{k}: {len(v)}개' for k,v in h.items()))"

table \
  "훅 시점" "|matcher| 동작" \
  -- \
  "UserPromptSubmit  |전체      스킬 추천" \
  "PreToolUse        |Edit|Write  main 브랜치 차단" \
  "PostToolUse       |Edit|Write  자동 포맷·의존성 설치·테스트 실행"

step_end