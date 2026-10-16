#!/usr/bin/env bash
# STEP 1 — 빈 디렉터리에서 프로젝트 시작 + Grok 템플릿 적용
# 데모 대상: template/grok/.grok/hooks/hooks.json, template/grok/AGENTS.md
source "$(dirname "$0")/../lib.sh"

step_begin 1 bootstrap "빈 폴더에서 시작하기"

APP="$DEMO_ROOT/todo-app"
TPL="$DEMO_ROOT/../../template/grok"

claude "빈 폴더에 Node.js 할 일 앱을 새로 만들자. 먼저 git 저장소를 초기화하고 feature 브랜치에서 시작해줘. main에서 직접 편집하지 않는 규칙을 지키고 싶어."

section "git 저장소 초기화"
expect "git init + 기본 브랜치 이름 main 지정" -- \
  git -C "$APP" init -q -b main

expect "첫 커밋 (빈 트리)" -- \
  git -C "$APP" -c user.email=demo@example.com -c user.name=demo commit -q \
    --allow-empty -m "chore: 프로젝트 시작"

note "이 시점에서 PreToolUse 훅이 활성화된다."

section "Grok 템플릿 적용"
expect "template/grok/.grok → 앱으로 복사" -- \
  cp -R "$TPL/.grok" "$APP/.grok"

note "복사된 항목:"
printf '  agents=%s  commands=%s  hooks=%s  skills=%s\n' \
  "$(find "$APP/.grok/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')" \
  "$(find "$APP/.grok/commands" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')" \
  "$(find "$APP/.grok/hooks" -type f 2>/dev/null | wc -l | tr -d ' ')" \
  "$(find "$APP/.grok/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')" \
  | tee -a "$LOG"

expect "template/grok/AGENTS.md → 앱 메모리로 복사" -- \
  cp "$TPL/AGENTS.md" "$APP/AGENTS.md"

section "Grok 는 이 파일들을 실제로 인식하는가"
if ! command -v grok >/dev/null 2>&1; then
  note "grok CLI 가 없어 이 단계는 건너뜁니다."
  note "설치: https://docs.x.ai/build"
else
  run "① 신뢰 전 — 아무것도 읽히지 않는다" -- \
    bash -c "cd '$APP' && grok inspect 2>&1 | grep -E '^  (Project Instructions|Skills|Agents|Hooks|MCP Servers)'"

  note ""
  note "에러가 안 났다. 그냥 0 개다. 파서가 아니라 신뢰 상태라는 뜻이다."
  note "이 함정을 알지 못하면 'Grok 가 우리 스킬을 못 읽는다' 하고 여기서 끝난다."

  note ""
  run "② --trust 후 — 전부 읽힌다" -- \
    bash -c "cd '$APP' && grok --trust inspect 2>&1 | grep -E '^  (Project Instructions|Skills|Agents|Hooks|MCP Servers)'"

  expect "우리 스킬 86개가 project 로 인식됐는지" -- \
    bash -c "cd '$APP' && grok --trust inspect 2>&1 | grep -q 'testing-patterns .*project'"

  expect "훅 3개가 등록됐는지" -- \
    bash -c "cd '$APP' && grok --trust inspect 2>&1 | grep -qE '^  Hooks \\(3\\)'"

  note ""
  note "AGENTS.md 를 지시 파일로 읽었다 — 이것이 Grok 세트의 기본값이다."
  note "CLAUDE.md 로 바꿔도 Grok 가 읽는다. 다른 도구까지 고려하면 AGENTS.md 가 표준이다."
fi

step_end