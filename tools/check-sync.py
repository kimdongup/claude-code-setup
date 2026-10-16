#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""두 세트(claude / grok)의 공유 콘텐츠가 어긋나지 않았는지 검사한다.

스킬 86개 · 명령 6개 · 에이전트 9개 · MCP · CI 는 두 세트에 **동일한 내용**이
들어 있어야 한다. Grok 세트는 다음만 달라야 한다.

  다른 것 (허용)
    위치        .claude/            vs  .grok/
    지시 파일   CLAUDE.md          vs  AGENTS.md
    훅 정의     settings.json 인라인 vs .grok/hooks/hooks.json
    훅 구현     Claude 전용        vs  hook-lib.sh 기반 이식 가능 버전
    에이전트 frontmatter  model/effort/permissionMode 유지 vs 제거

다른 것이 어긋나면 (위반)
    스킬/명령/에이전트 본문 내용
    MCP 서버 목록 · CI 워크플로
    Claude 세트의 훅이 Grok 규약에서 침묵하는지

사용법
    python3 tools/check-sync.py          검사만
    python3 tools/check-sync.py --diff   불일치 내용을 같이 출력
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLAUDE = ROOT / "template" / "claude"
GROK = ROOT / "template" / "grok"

# Claude Code 전용이라 Grok 에서 조용히 무시되는 에이전트 frontmatter
IGNORED_IN_GROK = {"model", "effort", "permissionMode"}

ok, bad = [], []


def digest(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


def rel(p: Path, base: Path) -> str:
    return str(p.relative_to(base))


def check_shared(flavor: str, c_dir: Path, g_dir: Path, c_map: Path, g_map: Path) -> None:
    """flavor ∈ {skills, commands} — 경로만 바뀌고 내용은 같아야 한다."""
    c_files = sorted(p for p in c_dir.rglob("*") if p.is_file())
    g_files = sorted(p for p in g_dir.rglob("*") if p.is_file())

    c_rel = {rel(p, c_dir) for p in c_files}
    g_rel = {rel(p, g_dir) for p in g_files}

    only_c, only_g = c_rel - g_rel, g_rel - c_rel
    if only_c:
        bad.append(f"[{flavor}] Claude 세트에만 있음: {sorted(only_c)[:5]}")
    if only_g:
        bad.append(f"[{flavor}] Grok 세트에만 있음: {sorted(only_g)[:5]}")

    cmp_map = {rel(p, c_dir): (p, g_dir / rel(p, c_dir)) for p in c_files if rel(p, c_dir) in g_rel}
    diff = [r for r, (a, b) in cmp_map.items() if digest(a) != digest(b)]
    if diff:
        bad.append(f"[{flavor}] 내용 불일치 {len(diff)}개: {diff[:5]}")
    else:
        ok.append(f"{flavor:<9} {len(cmp_map)}개 동일")


def frontmatter_keys(p: Path) -> list[str]:
    t = p.read_text(encoding="utf-8", errors="replace")
    if not t.startswith("---"):
        return []
    end = t.find("\n---", 3)
    if end < 0:
        return []
    return [m.group(1) for m in re.finditer(r"^([A-Za-z][\w-]*)\s*:", t[3:end], re.M)]


def frontmatter_body(p: Path) -> str:
    t = p.read_text(encoding="utf-8", errors="replace")
    end = t.find("\n---", 3)
    return t[end:] if t.startswith("---") and end > 0 else t


def check_agents(verbose: bool) -> None:
    c_dir, g_dir = CLAUDE / ".claude" / "agents", GROK / ".grok" / "agents"
    names = sorted(p.name for p in c_dir.glob("*.md"))
    missing = [n for n in names if not (g_dir / n).exists()]
    if missing:
        bad.append(f"[agents] Grok 세트에 없음: {missing}")
        return

    stripped, leaked = 0, []
    for n in names:
        ck, gk = frontmatter_keys(c_dir / n), frontmatter_keys(g_dir / n)
        dropped = set(ck) - set(gk)
        if dropped and dropped <= IGNORED_IN_GROK and not (set(gk) - set(ck)):
            # 빠진 키가 전부 "Grok 가 무시하는 필드" 라면 의도된 제거다
            stripped += 1
        elif set(ck) != set(gk):
            bad.append(f"[agents] frontmatter 키 불일치 {n}: claude={ck} grok={gk}")
        else:
            leaked.append(n)

        if frontmatter_body(c_dir / n) != frontmatter_body(g_dir / n):
            bad.append(f"[agents] 본문 불일치: {n}")

    ok.append(f"agents     {len(names)}개 · 무시필드 제거 {stripped}개")
    if leaked:
        bad.append(f"[agents] Grok 에서 무시되는 필드가 남아 있음: {leaked}")
    if verbose and stripped:
        print(f"  (제거된 필드: {', '.join(sorted(IGNORED_IN_GROK))})")


def check_json_pair(label: str, c: Path, g: Path) -> None:
    if not c.exists() or not g.exists():
        bad.append(f"[{label}] 파일 없음: {c.name if not c.exists() else g.name}")
        return
    try:
        cj, gj = json.loads(c.read_text()), json.loads(g.read_text())
    except Exception as e:
        bad.append(f"[{label}] JSON 파싱 실패: {e}")
        return
    if cj == gj:
        ok.append(f"{label:<9} 동일")
    else:
        only_c = set(cj) - set(gj)
        only_g = set(gj) - set(cj)
        bad.append(f"[{label}] 최상위 키 차이 — claude만={sorted(only_c)} grok만={sorted(only_g)}")


def check_ci() -> None:
    """CI 는 두 세트가 **구성 콘솔 하나씩** 갖는다는 것만 보장한다.
    본문은 세트마다 다르게 짜여 있고, 그게 맞다 —
    Claude 세트는 에이전트를 야간에 돌리고, Grok 세트는 결정론적 검사로 돌린다."""
    c_dir, g_dir = CLAUDE / ".github" / "workflows", GROK / ".github" / "workflows"
    c_files = sorted(p.name for p in c_dir.glob("*.yml"))
    g_files = sorted(p.name for p in g_dir.glob("*.yml"))

    if len(c_files) != len(g_files):
        bad.append(f"[CI] 워크플로 개수 불일치 claude={len(c_files)} grok={len(g_files)}")
    else:
        ok.append(f"CI        {len(c_files)}개씩 존재 (구성은 세트별 상이)")

    # 존재하지 않는 Action 을 참조하지 않았는지 확인한다.
    BOGUS = re.compile(r"uses:\s*anthropics/(?!claude-code-action)[\w-]+", re.I)
    for label, d in (("claude", c_dir), ("grok", g_dir)):
        for p in d.glob("*.yml"):
            m = BOGUS.search(p.read_text(encoding="utf-8", errors="replace"))
            if m:
                bad.append(f"[CI] {label}/{p.name} 존재하지 않는 Action 참조: {m.group(0)}")


def check_instruction_files() -> None:
    if (CLAUDE / "CLAUDE.md").exists():
        ok.append("지시 파일  claude/CLAUDE.md 존재")
    else:
        bad.append("[지시 파일] template/claude/CLAUDE.md 없음")
    if (GROK / "AGENTS.md").exists():
        ok.append("지시 파일  grok/AGENTS.md 존재")
    else:
        bad.append("[지시 파일] template/grok/AGENTS.md 없음")


def check_hooks_are_portable(verbose: bool) -> None:
    """Grok 세트의 훅이 Claude 전용 환경변수에 의존하지 않아야 한다."""
    g_hooks = GROK / ".grok" / "hooks"
    leaky = []
    for p in list(g_hooks.glob("*.sh")):
        if p.name == "hook-lib.sh":
            continue          # 헬퍼는 양쪽 이름을 모두 다루므로 정당한 예외
        body = p.read_text(encoding="utf-8", errors="replace")
        if "CLAUDE_TOOL_INPUT_FILE_PATH" in body or "CLAUDE_PROJECT_DIR" in body:
            leaky.append(p.name)
    if leaky:
        bad.append(f"[hooks] Grok 훅이 Claude 전용 환경변수에 의존: {leaky}")
    else:
        ok.append("hooks      Grok 훅은 하네스 독립")

    lib = g_hooks / "hook-lib.sh"
    if not lib.exists():
        bad.append("[hooks] hook-lib.sh 없음")
    elif verbose:
        t = lib.read_text(encoding="utf-8")
        need = ["CLAUDE_TOOL_INPUT_FILE_PATH", "GROK_HOOK_EVENT", "decision", "block"]
        miss = [k for k in need if k not in t]
        if miss:
            bad.append(f"[hooks] hook-lib.sh 에 필요한 항목 없음: {miss}")
        else:
            ok.append("hooks      hook-lib.sh 양쪽 규약 커버")


def main() -> int:
    verbose = "--diff" in sys.argv or "-v" in sys.argv

    if not CLAUDE.exists() or not GROK.exists():
        print("template/claude 또는 template/grok 가 없습니다.", file=sys.stderr)
        return 2

    check_shared("skills", CLAUDE / ".claude" / "skills", GROK / ".grok" / "skills", None, None)
    check_shared("commands", CLAUDE / ".claude" / "commands", GROK / ".grok" / "commands", None, None)
    check_agents(verbose)
    check_json_pair("mcp", CLAUDE / ".mcp.json", GROK / ".mcp.json")
    check_ci()
    check_instruction_files()
    check_hooks_are_portable(verbose)

    print("=" * 58)
    print("  두 세트 동기화 검사")
    print("=" * 58)
    for line in ok:
        print(f"  ✔ {line}")
    if bad:
        print()
        for line in bad:
            print(f"  ✘ {line}")
        print(f"\n  {len(bad)}건 불일치\n")
        return 1
    print("\n  두 세트는 의도한 차이만 가지고 있습니다.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())