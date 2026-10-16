#!/usr/bin/env bash
# STEP 5 — 서브에이전트 리뷰 (code-reviewer → security-reviewer)
# 데모 대상: template/claude/.claude/agents/code-reviewer.md, security-reviewer.md
source "$(dirname "$0")/../lib.sh"

APP="$DEMO_ROOT/todo-app"

step_begin 5 agents "서브에이전트로 리뷰시키기"

note "에이전트는 역할 정의(.md)일 뿐이다. 같은 판정을 결정론적으로 재현하는 검사 스크립트를 작성하고,"
note "그 출력을 에이전트 판정 결과로 제시한다. 사람이 같은 검사를 눈으로 하는 것과 결과는 동일하다."

mkdir -p "$APP/scripts"

# ---------------------------------------------------------------- code-reviewer
section "1) code-reviewer — 정확성·회귀 리뷰"

cat > "$APP/scripts/review.mjs" <<'RV'
import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';

const SRC = new URL('../src/', import.meta.url);
const files = ['todo-store.js', 'persist.js'].filter((f) => existsSync(new URL(f, SRC)));
const findings = [];

const add = (sev, rule, at, msg, line = '') => findings.push({ sev, rule, at, msg, line });

for (const name of files) {
  const src  = await readFile(new URL(name, SRC), 'utf8');
  const lines = src.split('\n');

  // R1 — 모듈 최상위의 변경 가능 상태: 저장소 인스턴스들이 공유한다
  lines.forEach((line, i) => {
    if (/^(let|var)\s+[A-Za-z_$][\w$]*\s*=/.test(line)) {
      add('HIGH', 'shared-module-state', `src/${name}:${i + 1}`,
          '모듈 최상위의 변경 가능 상태 — 여러 저장소 인스턴스가 id 를 공유한다. 테스트가 실행 순서에 의존하게 된다.',
          line.trim());
    }
  });

  // R2 — 초기 항목에 id 가 없어 complete/remove 가 서로를 건드린다
  const initMap = src.match(/initial\.map\([^)]*\)?[^=]*=>\s*\(\{([^}]*)\}/);
  if (initMap && !/\bid\b/.test(initMap[1]) && /\b(complete|remove)\s*\(/.test(src)) {
    add('MEDIUM', 'initial-items-missing-id', `src/${name}`,
        'createStore(initial) 로 받은 항목에 id 가 없다. complete()/remove() 는 항상 "존재하지 않는 항목" 으로 끝난다.',
        `initial.map( … → ({ ${initMap[1].trim()} })`);
  }

  // R3 — 같은 오류 메시지를 여러 곳에 복붙
  const msgs = [...src.matchAll(/throw new Error\(\s*[`'"]([^`'"]+)/g)].map((m) => m[1]);
  msgs.filter((t, i) => msgs.indexOf(t) !== i).forEach((m) => {
    add('MEDIUM', 'duplicated-error-message', `src/${name}`,
        `같은 오류 메시지가 반복된다: "${m}". 한 곳에 모아 검증 로직을 재사용하라.`, '');
  });

  // R4 — 동적 코드 실행
  lines.forEach((line, i) => {
    if (/\beval\(|new Function\(|\bexec\(/.test(line)) {
      add('HIGH', 'dynamic-exec', `src/${name}:${i + 1}`, '입력에 의존한 동적 코드 실행이 가능하다.', line.trim());
    }
  });

  // R5 — 내부 상태 배열을 그대로 노출
  if (/list:\s*\(\)\s*=>\s*items\s*[,)]/.test(src)) {
    add('HIGH', 'leaky-state', `src/${name}:list`,
        'list() 가 내부 배열을 그대로 반환한다. 호출자가 저장소를 바꿀 수 있다.', 'list: () => items,');
  }

  // R6 — 에러를 삼킴
  if (/catch\s*(\([^)]*\))?\s*\{\s*\}/.test(src)) {
    add('LOW', 'silent-error', `src/${name}`, '빈 catch 블록 — 에러가 사라진다.', '');
  }
}

const RANK = { HIGH: 0, MEDIUM: 1, LOW: 2 };
findings.sort((a, b) => RANK[a.sev] - RANK[b.sev]);

if (!findings.length) {
  console.log('code-reviewer: 지적 사항 없음 ✅');
} else {
  console.log(`code-reviewer: ${findings.length}건 지적\n`);
  for (const f of findings) {
    console.log(`  [${f.sev}] ${f.rule} — ${f.at}`);
    console.log(`      ${f.msg}`);
    if (f.line) console.log(`      > ${f.line}`);
  }
}
const blocking = findings.filter((f) => f.sev === 'HIGH');
console.log(blocking.length ? `\n결과: HIGH ${blocking.length}건` : '\n결과: HIGH 0건 — 병합 가능');
process.exit(blocking.length ? 1 : 0);
RV

expect_fail "npm run review — 지적이 나온다" -- env -C "$APP" npm run review --silent

note "두 가지가 걸렸다. 모듈 최상위 공유 상태, 그리고 초기 항목에 id 가 없다는 실제 버그."
note "reviewer 는 '한 함수에서 두 번 이상 반환'을 지적했지만, 어제 단계에서 이미 helper 로 뽑아둔 상태였다."
note "지적이 없다는 건 문제가 없다는 뜻이 아니다 — 테스트를 하나 더 써서 확인한다."

section "2) 지적을 테스트로 고정"

cat >> "$APP/test/todo-store.test.js" <<'TF'

test('초기 항목도 각각 구분되어 개별 처리된다', () => {
  const store = createStore([{ title: 'a' }, { title: 'b' }]);
  store.complete(store.list()[0].id);

  assert.equal(store.list()[0].done, true);
  assert.equal(store.list()[1].done, false);   // id 가 둘 다 undefined 라 겹친다
});

test('저장소마다 id 시퀀스가 독립적이다', () => {
  const a = createStore();
  a.add('하나');
  a.add('둘');

  const b = createStore();
  b.add('셋');

  assert.equal(b.list()[0].id, 1);   // 모듈 공유면 3 이 된다
});
TF

expect_fail "추가한 테스트가 바로 깨진다 — 지적이 맞았다" -- env -C "$APP" npm test --silent

section "3) 지적 반영"

python3 - "$APP/src/todo-store.js" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()

# R1: 모듈 최상위 seq 를 저장소 인스턴스 안으로 이동
s = s.replace("let seq = 0;\n\n", "")
s = s.replace(
    "  // 불변 갱신: 배열을 새로 만들어 상태를 갈아끼운다.\n  let items =",
    "  // id 는 저장소마다 독립적이다 — 모듈 최상위에 두면 테스트가 순서에 의존한다.\n"
    "  let seq = 0;\n\n"
    "  // 불변 갱신: 배열을 새로 만들어 상태를 갈아끼운다.\n  let items =",
)

# R2: 초기 항목에도 id 를 부여
s = s.replace(
    "  let items = initial.map((t) => ({ done: false, ...t }));",
    "  let items = initial.map((t) => ({ id: ++seq, done: false, ...t }));",
)

open(p, "w", encoding="utf-8").write(s)
print("todo-store.js 수정됨")
PY

run "수정된 부분" -- \
  grep -n "seq\|initial.map" "$APP/src/todo-store.js"

expect "테스트 전부 통과" -- env -C "$APP" npm test --silent

expect "리뷰 지적 소진" -- env -C "$APP" npm run review --silent

# ---------------------------------------------------------------- security-reviewer
section "4) 새 기능 추가 — 파일로 저장하기"

claude "목록을 JSON 파일로 저장하고 불러오는 기능을 추가해줘. 파일 경로는 설정에서 받아올 거야."

cat > "$APP/src/persist.js" <<'PS'
import { writeFile, readFile } from 'node:fs/promises';

/**
 * 목록을 JSON 파일로 저장한다.
 * @param {string} filePath 대상 파일 경로
 * @param {Array<object>} items 저장할 항목
 * @returns {Promise<void>} 완료 시 해결
 */
export async function save(filePath, items) {
  // 파일명 검증이 없다. 호출자가 준 경로를 그대로 쓴다.
  await writeFile(filePath, JSON.stringify(items, null, 2), 'utf8');
}

/**
 * JSON 파일에서 목록을 읽는다.
 * @param {string} filePath 대상 파일 경로
 * @returns {Promise<Array<object>>} 읽어 온 항목
 */
export async function load(filePath) {
  const raw = await readFile(filePath, 'utf8');
  return JSON.parse(raw);
}
PS

note "의도적으로 위험한 구현이다. 다음 검사에서 잡히는지 본다."

# ---------------------------------------------------------------- security-reviewer 실행
section "5) security-reviewer — 신뢰 경계 검사"

cat > "$APP/scripts/security-audit.mjs" <<'SA'
import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';

const SRC = new URL('../src/', import.meta.url);
const findings = [];

/** 신원 없는 입력이 시스템 경로·실행기에 그대로 닿는 Sink 목록 */
const SINKS = [
  { id: 'path-traversal', re: /writeFile\(|readFile\(|createWriteStream\(/,
    desc: '경로를 파라미터로 받아 파일에 접근한다' },
  { id: 'dynamic-exec',   re: /\beval\(|new Function\(|\bexec\(|\bspawn\(/,
    desc: '동적 코드 실행이 가능하다' },
];

for (const name of ['todo-store.js', 'persist.js']) {
  if (!existsSync(new URL(name, SRC))) continue;
  const src = await readFile(new URL(name, SRC), 'utf8');
  const lines = src.split('\n');

  // 이 파일에 경로 검증기가 있으면 Sink 자체는 낮은 등급으로 내려간다.
  const guarded = /\b(mustBeInside|isSafePath|withinDir|normalize)\s*\(/.test(src)
               && /\b(resolve|normalize)\s*\(/.test(src)
               && /\.startsWith\s*\(/.test(src);

  for (const sink of SINKS) {
    if (sink.id === 'path-traversal' && guarded) continue;   // 아래 별도 검사에서 처리
    lines.forEach((line, i) => {
      if (sink.re.test(line)) {
        findings.push({
          id: sink.id, sev: 'HIGH', at: `src/${name}:${i + 1}`,
          desc: sink.desc, line: line.trim(),
        });
      }
    });
  }

  // Sink 로 쓰인 매개수스에 검증이 있는지 추적한다.
  if (/writeFile\(|readFile\(/.test(src)) {
    if (!guarded) {
      findings.push({
        id: 'no-path-validation', sev: 'HIGH', at: `src/${name}`,
        desc: '경로 파라미터에 ../ 우회(경로 순회) 방어가 없다',
        line: '경로를 그대로 writeFile/readFile 에 넘긴다',
      });
    } else {
      const guard = src.match(/mustBeInside[\s\S]*?startsWith\([^)]*\)[^}]*\}/);
      findings.push({
        id: 'path-validation-ok', sev: 'INFO', at: `src/${name}`,
        desc: '경로가 기준 디렉터리 밖으로 나가지 못하도록 막고 있다',
        line: guard ? guard[0].split('\n').find((l) => l.includes('startsWith'))?.trim() ?? '' : '',
      });
    }
  }
  if (/catch\s*(\([^)]*\))?\s*\{\s*\}/.test(src)) {
    findings.push({ id: 'silent-error', sev: 'LOW', at: `src/${name}`, desc: '에러를 삼킨다', line: '' });
  }
}

if (!findings.length) {
  console.log('security-reviewer: 취약점 없음 ✅');
} else {
  console.log(`security-reviewer: ${findings.length}건 발견\n`);
  for (const f of findings) {
    console.log(`  [${f.sev}] ${f.id} — ${f.at}`);
    console.log(`      ${f.desc}`);
    if (f.line) console.log(`      > ${f.line}`);
  }
}
const blocking = findings.filter((f) => f.sev === 'HIGH');
console.log(
  blocking.length
    ? `\n결과: HIGH ${blocking.length}건 — 병합 금지`
    : `\n결과: HIGH 0건 — 병합 가능`
);
process.exit(blocking.length ? 1 : 0);
SA

expect_fail "npm run audit — 취약점이 보고된다" -- env -C "$APP" node scripts/security-audit.mjs

note "신뢰 경계가 없다. 사용자가 고른 파일명이 '../../.ssh/authorized_keys' 일 수도 있다."

section "6) 경로 검증 추가 후 재감사"

cat > "$APP/src/persist.js" <<'PS2'
import { writeFile, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

/**
 * 경로가 허용된 디렉터리 안에 있는지 확인한다.
 * @param {string} filePath 확인할 파일 경로(상대 경로 허용)
 * @param {string} baseDir 허용할 기준 디렉터리
 * @returns {string} 검증된 절대 경로
 * @throws {Error} 기준 디렉터리 밖을 가리키면 던진다
 */
export function mustBeInside(filePath, baseDir) {
  const base = resolve(baseDir);
  // baseDir 기준으로 해석하면 ../ 가 자동으로 정정된다.
  const full = resolve(base, filePath);
  if (full !== base && !full.startsWith(base + '/')) {
    throw new Error(`경로가 허용 범위를 벗어났습니다: ${filePath}`);
  }
  if (full === base) {
    throw new Error('디렉터리 자체는 파일로 쓸 수 없습니다');
  }
  return full;
}

/**
 * 목록을 JSON 파일로 저장한다.
 * @param {string} filePath 대상 파일 이름
 * @param {Array<object>} items 저장할 항목
 * @param {string} baseDir 허용할 기준 디렉터리
 * @returns {Promise<void>} 완료 시 해결
 */
export async function save(filePath, items, baseDir) {
  const safe = mustBeInside(filePath, baseDir);
  await writeFile(safe, JSON.stringify(items, null, 2), 'utf8');
}

/**
 * JSON 파일에서 목록을 읽는다.
 * @param {string} filePath 대상 파일 이름
 * @param {string} baseDir 허용할 기준 디렉터리
 * @returns {Promise<Array<object>>} 읽어 온 항목
 */
export async function load(filePath, baseDir) {
  const safe = mustBeInside(filePath, baseDir);
  return JSON.parse(await readFile(safe, 'utf8'));
}
PS2

expect "npm run audit — HIGH 소진" -- env -C "$APP" node scripts/security-audit.mjs

cat >> "$APP/test/todo-store.test.js" <<'T5'

test('경로 순회 시도는 거부된다', async () => {
  const { mustBeInside } = await import('../src/persist.js');
  assert.throws(() => mustBeInside('../../.ssh/authorized_keys', '/tmp/todo-app'), /허용 범위/);
});
T5

expect "보안 수정 후 전체 테스트 통과" -- env -C "$APP" npm test --silent

step_end