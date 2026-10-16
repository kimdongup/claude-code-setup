#!/usr/bin/env bash
# STEP 3 — TDD로 도메인 구현 (red → green → refactor)
# 데모 대상: template/claude/.claude/skills/testing-patterns/SKILL.md
source "$(dirname "$0")/../lib.sh"

APP="$DEMO_ROOT/todo-app"

step_begin 3 tdd "TDD로 할 일 도메인 만들기"

claude "testing-patterns 스킬을 적용해서 할 일 도메인을 만들어줘. 빨강 상태로 시작하고, 한 번에 하나씩 테스트를 추가해. 아무것도 없는 모듈이니까 첫 테스트는 당연히 실패해야 해."

note "스킬은 작업 전에 Claude에게 읽히는 사용법 문서다. 여기서는 그 절차만 그대로 실행한다."

mkdir -p "$APP/src" "$APP/test"
cat > "$APP/package.json" <<'PKG'
{
  "name": "todo-app",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "test": "node --test",
    "test:watch": "node --test --watch",
    "review": "node scripts/review.mjs",
    "audit": "node scripts/security-audit.mjs",
    "quality": "node scripts/quality.mjs"
  },
  "dependencies": {},
  "devDependencies": {}
}
PKG

note "의존성이 0개여도 npm audit 는 락파일을 요구한다. 한 번 만들어 둔다."
expect "package-lock.json 생성" -- env -C "$APP" npm install --package-lock-only --silent --no-audit --no-fund

# ---------------------------------------------------------------- 1. RED
section "1) RED — 실패하는 테스트를 먼저 쓴다"
note "소스는 아직 없다. 실패해야 정상이다."

cat > "$APP/test/todo-store.test.js" <<'T1'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/todo-store.js';

test('빈 저장소에서 목록을 조회하면 0건이다', () => {
  // Arrange
  const store = createStore();

  // Act
  const items = store.list();

  // Assert
  assert.equal(items.length, 0);
});
T1

expect_fail "npm test (아직 실패해야 한다)" -- \
  env -C "$APP" npm test --silent

note "여기서 Claude Code의 PostToolUse 훅이 자동으로 npm test 를 돌렸을 것이다."

# ---------------------------------------------------------------- 2. GREEN
section "2) GREEN — 통과하는 최소 구현"
note "테스트가 통과하는 가장 작은 코드만 쓴다."

cat > "$APP/src/todo-store.js" <<'S1'
export function createStore(initial = []) {
  return {
    list: () => initial,
  };
}
S1

expect "npm test (통과해야 한다)" -- env -C "$APP" npm test --silent

# ---------------------------------------------------------------- 3. RED
section "3) RED — 다음 동작: 항목 추가"
cat > "$APP/test/todo-store.test.js" <<'T2'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/todo-store.js';

test('빈 저장소에서 목록을 조회하면 0건이다', () => {
  const store = createStore();
  const items = store.list();
  assert.equal(items.length, 0);
});

test('항목을 추가하면 목록에 1건이 생긴다', () => {
  // Arrange
  const store = createStore();

  // Act
  store.add('장보기');

  // Assert
  assert.deepEqual(store.list().map((t) => t.title), ['장보기']);
});

test('추가한 항목은 미완료 상태로 시작한다', () => {
  const store = createStore();
  store.add('장보기');
  assert.equal(store.list()[0].done, false);
});
T2

expect_fail "npm test (구현 전이므로 실패)" -- env -C "$APP" npm test --silent

# ---------------------------------------------------------------- 4. GREEN
section "4) GREEN — 추가 동작 구현"
cat > "$APP/src/todo-store.js" <<'S2'
let seq = 0;

/**
 * 할 일 저장소를 만든다.
 * @param {{title: string, done?: boolean}[]} [initial] 초기 항목 목록
 * @returns {{list: Function, add: Function}} 저장소 객체
 */
export function createStore(initial = []) {
  // 불변 갱신: 배열을 새로 만들어 상태를 갈아끼운다.
  let items = initial.map((t) => ({ done: false, ...t }));

  return {
    list: () => items.map((t) => ({ ...t })),

    /**
     * 항목을 추가한다.
     * @param {string} title 할 일 제목
     * @returns {void}
     */
    add(title) {
      if (typeof title !== 'string' || title.trim() === '') {
        throw new Error('할 일 제목은 비어 있을 수 없습니다');
      }
      items = [...items, { id: ++seq, title: title.trim(), done: false }];
    },
  };
}
S2

expect "npm test (통과해야 한다)" -- env -C "$APP" npm test --silent

# ---------------------------------------------------------------- 5. RED
section "5) RED — 완료 처리와 삭제"
cat >> "$APP/test/todo-store.test.js" <<'T3'

test('항목을 완료하면 done이 true가 된다', () => {
  const store = createStore();
  store.add('장보기');
  store.complete(store.list()[0].id);
  assert.equal(store.list()[0].done, true);
});

test('없는 id를 완료하면 에러를 던진다', () => {
  const store = createStore();
  assert.throws(() => store.complete(999), /존재하지/);
});

test('항목을 삭제하면 목록에서 사라진다', () => {
  const store = createStore();
  store.add('장보기');
  store.remove(store.list()[0].id);
  assert.equal(store.list().length, 0);
});
T3

expect_fail "npm test (아직 미구현)" -- env -C "$APP" npm test --silent

# ---------------------------------------------------------------- 6. GREEN
section "6) GREEN — 완료/삭제 구현"
cat > "$APP/src/todo-store.js" <<'S3'
let seq = 0;

/**
 * 할 일 저장소를 만든다.
 * @param {{title: string, done?: boolean}[]} [initial] 초기 항목 목록
 * @returns {{list: Function, add: Function, complete: Function, remove: Function, stats: Function}} 저장소 객체
 */
export function createStore(initial = []) {
  // 불변 갱신: 배열을 새로 만들어 상태를 갈아끼운다.
  let items = initial.map((t) => ({ done: false, ...t }));

  const find = (id) => {
    const hit = items.find((t) => t.id === id);
    if (!hit) throw new Error(`존재하지 않는 항목입니다: ${id}`);
    return hit;
  };

  return {
    /** @returns {Array<{id: number, title: string, done: boolean}>} 현재 항목 목록(복사본) */
    list: () => items.map((t) => ({ ...t })),

    /**
     * 항목을 추가한다.
     * @param {string} title 할 일 제목
     * @returns {void}
     */
    add(title) {
      if (typeof title !== 'string' || title.trim() === '') {
        throw new Error('할 일 제목은 비어 있을 수 없습니다');
      }
      items = [...items, { id: ++seq, title: title.trim(), done: false }];
    },

    /**
     * 항목을 완료 처리한다.
     * @param {number} id 완료할 항목 id
     * @returns {void}
     */
    complete(id) {
      const hit = find(id);
      items = items.map((t) => (t.id === hit.id ? { ...t, done: true } : t));
    },

    /**
     * 항목을 삭제한다.
     * @param {number} id 삭제할 항목 id
     * @returns {void}
     */
    remove(id) {
      find(id);
      items = items.filter((t) => t.id !== id);
    },

    /**
     * 집계 값을 계산한다.
     * @returns {{total: number, done: number, open: number}} 전체/완료/미완료 건수
     */
    stats: () => {
      const done = items.filter((t) => t.done).length;
      return { total: items.length, done, open: items.length - done };
    },
  };
}
S3

expect "npm test (전부 통과)" -- env -C "$APP" npm test --silent

# ---------------------------------------------------------------- 7. REFACTOR
section "7) REFACTOR — 그대로 두고 통계 테스트를 추가"
cat >> "$APP/test/todo-store.test.js" <<'T4'

test('통계는 전체/완료/미완료 건수를 센다', () => {
  const store = createStore();
  store.add('a');
  store.add('b');
  store.complete(store.list()[0].id);

  assert.deepEqual(store.stats(), { total: 2, done: 1, open: 1 });
});
T4

expect "리팩터링 후에도 회귀 없음" -- env -C "$APP" npm test --silent

note "red → green → refactor 3회를 거쳤고, 마지막에 테스트가 8개다."

step_end