#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""example/logs/*.log → example/walkthrough.html (스크린샷 가이드)

로그를 그대로 읽어 터미널 창 모양으로 렌더링한다.
외부 이미지·폰트·스크립트 없이 단일 파일로 동작한다.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
LOG_DIR = HERE / "logs"
OUT = HERE / "walkthrough.html"

# ───────────────────────────────────────────── 단계 메타데이터
STEPS = [
    dict(
        n=1, slug="bootstrap", title="빈 폴더에서 시작하기",
        asks="빈 폴더에 Node.js 할 일 앱을 새로 만들자. 먼저 git 저장소를 초기화하고 feature 브랜치에서 시작해줘. main에서 직접 편집하지 않는 규칙을 지키고 싶어.",
        parts=[
            ("`.claude/settings.json`", "`UserPromptSubmit` · `PreToolUse` · `PostToolUse` 훅 3종이 정의돼 있다. 앱을 시작하는 시점에 이 파일이 함께 들어온다."),
            ("`.claude/agents/` · `skills/`", "역할 9개와 지식 86개가 붙는다. 지시하지 않아도 `/code-reviewer` 같은 호출이 가능해진다."),
            ("`CLAUDE.md`", "세션마다 읽히는 기억 파일의 자리를 먼저 확보한다."),
        ],
        key="템플릿은 `.claude/` 한 덩어리다. 파일을 만드는 게 아니라 **설정 자산을 옮기는 것**이 설치다.",
    ),
    dict(
        n=2, slug="memory", title="프로젝트 기억 만들기",
        asks="이 프로젝트는 의존성 없이 Node.js 내장 테스트 러너(node:test)만 쓴다. … 이 규칙을 CLAUDE.md에 기록해줘.",
        parts=[
            ("`CLAUDE.md`", "스택·금지 사항·자주 쓰는 명령까지 적어두면, 매 세션마다 반복 프롬프트를 안 해도 같은 규칙이 적용된다."),
            ("`skills/*/SKILL.md`", "메모리가 '이 프로젝트 규칙'이라면 스킬은 '잘하는 방법'이다. 둘은 목적이 다르니 나눠 쓴다."),
            ("`agents/*.md`", "메모리가 규칙이면 에이전트는 역할이다. `description`에 언제 쓸지 써야 Claude가 자동으로 고른다."),
        ],
        key="좋은 CLAUDE.md 는 **부재**를 적는다. '하지 말 것'을 명시해야 안 하는 일이 안 일어난다.",
    ),
    dict(
        n=3, slug="tdd", title="TDD로 도메인 만들기",
        asks="testing-patterns 스킬을 적용해서 할 일 도메인을 만들어줘. 빨강 상태로 시작하고, 한 번에 하나씩 테스트를 추가해.",
        parts=[
            ("`skills/testing-patterns/SKILL.md`", "'프로덕션 코드 전에 실패하는 테스트를 먼저 쓴다'를 강제하는 스킬. 실제로 빨강→초록→리팩터 3회를 반복했다."),
            ("`testing-patterns` 규칙", "테스트 이름은 `test('<조건> → <기대>')`. 세기가 Arrange/Act/Assert 세 블록으로 갈린다."),
        ],
        key="테스트가 통과하기 **전**에 보인 실패가 있다는 게 이 단계의 증거다. 스크립트가 실제로 실행되어 녹화되어 있다.",
    ),
    dict(
        n=4, slug="hooks", title="훅이 규칙을 지킨다",
        asks="설정에 들어 있는 훅이 정말 동작하는지 확인해줘. … 이 프로젝트에 맞게 고쳐줘.",
        parts=[
            ("`PreToolUse` 훅", "`main` 브랜치에서 파일을 고치면 `exit 2`로 차단한다. 로그 1단계에서 실제로 막힌 것을 확인할 수 있다."),
            ("`PostToolUse` 훅", "`.test.js` 를 건드리면 자동 테스트. 그런데 템플릿 기본값이 **Jest 전용 플래그**라 이 프로젝트에서 실패한다."),
            ("읽고 고치는 정상 흐름", "훅을 그대로 신뢰하지 않고 실제로 돌려보고, 프로젝트에 맞게 고친다. Prettier 훅도 '의존성 0개' 원칙 때문에 껐다."),
        ],
        key="훅은 **고정된 규칙**이다. 템플릿의 기본값은 예시일 뿐이므로, 첫날에 반드시 한 번씩 돌려봐야 한다.",
    ),
    dict(
        n=5, slug="agents", title="서브에이전트로 리뷰시키기",
        asks="@code-reviewer 방금 만든 src/ 를 리뷰해줘.\n@security-reviewer 새로 추가한 persist.js 도 봐줘. 외부 입력이 파일 시스템에 닿는 부분이 있나?",
        parts=[
            ("`agents/code-reviewer.md`", "`let seq = 0` 이 모듈 최상위다. 저장소 인스턴스가 id 를 공유해서 테스트가 실행 순서에 의존하게 된다 — 지적 1."),
            ("`agents/code-reviewer.md`", "`createStore(initial)` 이 받은 항목에 `id` 가 없다. 두 항목을 넣으면 둘 다 `id === undefined` 여서 `complete()` 이 둘을 동시에 건드린다 — 지적 2."),
            ("`agents/security-reviewer.md`", "`persist.js` 의 `writeFile(filePath)` 에 경로 검증이 없다. `../../.ssh/authorized_keys` 로 어디든 쓸 수 있다."),
            ("`description` 필드가 라우팅", "에이전트가 자동 선택되는 기준은 이름이 아니라 `description` 문장이다. '~할 때 사용' 형식이 실전에서 잘 통한다."),
        ],
        key="두 에이전트 다 **재현 가능한 판정**으로 바꿔 담았다. 같은 파일에 다시 돌리면 같은 결과가 나온다.",
    ),
    dict(
        n=6, slug="quality", title="명령으로 돌리고 CI로 지킨다",
        asks="/code-quality src\n\n그리고 이 결과가 CI에서 막히게 만들어줘.",
        parts=[
            ("`commands/code-quality.md`", "`$ARGUMENTS` 로 대상 디렉터리를 받는 슬래시 명령. 검사 목록이 이미 문서화돼 있다."),
            ("`.github/workflows/ci.yml`", "PR이 올라오면 테스트→리뷰→보안→의존성 감사가 자동으로 돌고, 하나라도 실패하면 병합이 막힌다."),
            ("`includeCoAuthoredBy`", "`settings.json` 의 값이 그대로 커밋 trailer에 반영된다."),
        ],
        key="로컬에서 '기록만 남는 대시보드'와 CI에서 '병합을 막는 게이트'는 다르다. 6단계는 그 차이를 만든다.",
    ),
]

ANSWER = {
    1: "빈 저장소 + 템플릿 적용",
    2: "프로젝트 규칙을 CLAUDE.md 에 기록",
    3: "테스트가 깨지는 것부터 시작해 도메인 구현",
    4: "설정의 훅을 실제 실행해 검증하고 프로젝트에 맞게 수정",
    5: "code-reviewer 와 security-reviewer 로 지적을 받고 반영",
    6: "/code-quality 로 게이트를 만들고 CI로 고정",
}

TERMINAL_ICON = "● ● ●"


def ansi_to_html(text: str) -> str:
    """ANSI escape → span. 로그는 NO_COLOR 로 돌아와 색이 없지만 안전장치로 둔다."""
    pat = re.compile(r"\x1b\[([0-9;]*)m")
    out, last, open_spans = [], 0, 0
    for m in pat.finditer(text):
        out.append(html.escape(text[last:m.start()]))
        last = m.end()
        codes = m.group(1)
        if codes in ("", "0"):
            out.append("</span>" * open_spans)
            open_spans = 0
        else:
            out.append('<span class="a' + re.sub(r"\D", "", codes) + '">')
            open_spans += 1
    out.append(html.escape(text[last:]))
    out.append("</span>" * open_spans)
    return "".join(out)


def read_log(step) -> str | None:
    p = LOG_DIR / f"{step['n']}-{step['slug']}.log"
    if not p.exists():
        return None
    return p.read_text(encoding="utf-8", errors="replace").rstrip()


def terminal(step, body: str) -> str:
    title = f"{step['slug']} — {ANSWER[step['n']]}"
    return f"""<figure class="shot">
  <div class="term">
    <div class="bar"><span class="dots">{TERMINAL_ICON}</span><span class="ttl">{html.escape(title)}</span></div>
    <pre class="body">{ansi_to_html(body)}</pre>
  </div>
  <figcaption>{html.escape(f"example/claude/logs/{step['n']}-{step['slug']}.log")}</figcaption>
</figure>"""


CSS = """
*{box-sizing:border-box}
:root{
  --bg:#0d1117; --panel:#161b22; --line:#30363d; --fg:#e6edf3;
  --dim:#8b949e; --acc:#58a6ff; --ok:#3fb950; --warn:#d29922; --bad:#f85149;
  --card:#11161d;
}
html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--fg);
  font-family:-apple-system,BlinkMacSystemFont,"Apple SD Gothic Neo","Noto Sans KR",Segoe UI,sans-serif;
  line-height:1.7;-webkit-font-smoothing:antialiased}
a{color:var(--acc);text-decoration:none}
a:hover{text-decoration:underline}

header{padding:54px 28px 30px;border-bottom:1px solid var(--line);
  background:radial-gradient(900px 300px at 20% -40%,#1f6feb22,transparent)}
header h1{margin:0 0 10px;font-size:clamp(24px,4vw,38px);letter-spacing:-.02em}
header p{margin:0;color:var(--dim);max-width:760px}
.badges{margin-top:18px;display:flex;gap:8px;flex-wrap:wrap}
.badge{font-size:12px;padding:4px 11px;border:1px solid var(--line);border-radius:999px;
  background:var(--panel);color:var(--dim)}
.badge b{color:var(--fg);font-weight:600}

.wrap{display:grid;grid-template-columns:250px minmax(0,1fr);gap:38px;
  max-width:1320px;margin:0 auto;padding:34px 24px 90px}

nav{position:sticky;top:22px;align-self:start;max-height:calc(100vh - 44px);overflow:auto}
nav h2{font-size:11px;letter-spacing:.14em;color:var(--dim);text-transform:uppercase;
  margin:0 0 10px;padding-left:12px}
nav ol{list-style:none;margin:0;padding:0;counter-reset:s}
nav a{display:flex;gap:10px;padding:8px 12px;border-radius:8px;color:var(--dim);
  font-size:13.5px;border-left:2px solid transparent}
nav a:hover{background:var(--panel);color:var(--fg);text-decoration:none}
nav a.on{background:var(--panel);color:var(--fg);border-left-color:var(--acc)}
nav a i{font-style:normal;color:var(--acc);font-variant-numeric:tabular-nums;font-size:12px;padding-top:1px}

section.step{margin:0 0 60px;scroll-margin-top:20px}
section.step > h3{margin:0 0 4px;font-size:23px;letter-spacing:-.01em;display:flex;gap:11px;align-items:baseline}
section.step > h3 em{font-style:normal;color:var(--acc);font-size:14px;font-variant-numeric:tabular-nums}
.stepgoal{margin:0 0 20px;color:var(--dim);font-size:14px}

.ask{background:var(--card);border:1px solid var(--line);border-left:3px solid var(--warn);
  border-radius:9px;padding:15px 18px;margin:0 0 26px}
.ask b{display:block;font-size:11px;letter-spacing:.11em;color:var(--warn);
  text-transform:uppercase;margin-bottom:7px}
.ask p{margin:0;color:#d7e0ea;font-size:14.5px}

.parts{list-style:none;margin:0 0 26px;padding:0;display:grid;gap:10px}
.parts li{background:var(--panel);border:1px solid var(--line);border-radius:9px;padding:13px 16px;
  font-size:14px;color:#c9d3de}
.parts code,.key code,td code,.steps code{background:#0b0f14;border:1px solid var(--line);
  border-radius:5px;padding:1.5px 5px;font-size:12.5px;color:#a5d6ff;
  font-family:ui-monospace,SFMono-Regular,Menlo,monospace}

.shot{margin:0 0 22px}
.term{border:1px solid var(--line);border-radius:11px;overflow:hidden;
  background:#010409;box-shadow:0 10px 34px #0009}
.bar{display:flex;align-items:center;gap:12px;padding:9px 14px;
  background:linear-gradient(#1c2128,#161b22);border-bottom:1px solid var(--line)}
.dots{letter-spacing:5px;color:#3d444d;font-size:11px;user-select:none}
.ttl{font-size:12px;color:var(--dim);font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
pre.body{margin:0;padding:15px 17px;font-size:12.5px;line-height:1.62;
  font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:#cdd9e5;
  white-space:pre-wrap;overflow-wrap:anywhere;tab-size:4}
pre.body .a31{color:#f85149}pre.body .a32{color:#3fb950}pre.body .a33{color:#d29922}
pre.body .a36{color:#39c5cf}pre.body .a34{color:#58a6ff}pre.body .a1{font-weight:700}
figcaption{margin-top:7px;font-size:11.5px;color:#6e7681;
  font-family:ui-monospace,SFMono-Regular,Menlo,monospace}

.key{background:linear-gradient(90deg,#1f6feb14,transparent);border:1px solid var(--line);
  border-left:3px solid var(--acc);border-radius:9px;padding:14px 18px;font-size:14.5px}
.key b{color:var(--acc);font-size:11px;letter-spacing:.11em;text-transform:uppercase;
  display:block;margin-bottom:5px}
.missing{background:var(--panel);border:1px dashed var(--line);border-radius:9px;
  padding:22px;color:var(--dim);font-size:14px;text-align:center}

.steps{background:var(--panel);border:1px solid var(--line);border-radius:11px;
  padding:20px 22px;margin-top:6px}
.steps h4{margin:0 0 12px;font-size:12px;letter-spacing:.12em;color:var(--dim);
  text-transform:uppercase}
.steps table{width:100%;border-collapse:collapse;font-size:13.5px}
.steps td{padding:7px 0;border-bottom:1px solid #21262d;vertical-align:top}
.steps td:first-child{color:var(--acc);white-space:nowrap;width:110px;font-weight:600}
.steps tr:last-child td{border-bottom:0}

footer{border-top:1px solid var(--line);padding:26px 24px 60px;color:var(--dim);
  font-size:13px;text-align:center}

@media(max-width:900px){
  .wrap{grid-template-columns:1fr;gap:22px}
  nav{position:static;max-height:none;border-bottom:1px solid var(--line);padding-bottom:16px}
  nav ol{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:2px}
}
"""


JS = """
<script>
(function () {
  var links = [].slice.call(document.querySelectorAll('nav a'));
  var secs  = links.map(function (a) { return document.querySelector(a.getAttribute('href')); });
  if (!secs.length) return;

  function mark() {
    // 화면 위쪽 140px 안에 들어온 마지막 구간을 현재 위치로 본다
    var cur = 0;
    for (var i = 0; i < secs.length; i++) {
      if (secs[i] && secs[i].getBoundingClientRect().top <= 140) cur = i;
    }
    // 페이지 맨 아래면 마지막 구간을 선택
    if (window.innerHeight + window.pageYOffset >= document.body.scrollHeight - 4) {
      cur = secs.length - 1;
    }
    links.forEach(function (l, i) { l.classList.toggle('on', i === cur); });
  }

  window.addEventListener('scroll', mark, { passive: true });
  window.addEventListener('resize', mark);
  window.addEventListener('hashchange', mark);
  mark();
})();
</script>
"""


def build() -> str:
    parts_html, nav_html = [], []
    total_done = 0

    for s in STEPS:
        nav_html.append(
            f'<li><a href="#step-{s["n"]}"><i>{s["n"]:02d}</i><span>{html.escape(s["title"])}</span></a></li>'
        )
        log = read_log(s)
        if log:
            total_done += 1
            shot = terminal(s, log)
        else:
            shot = '<div class="missing">아직 실행되지 않은 단계입니다 — <code>./example/run-demo.sh</code> 를 실행하세요.</div>'

        pli = "".join(
            f"<li><code>{html.escape(a)}</code> — {html.escape(b)}</li>" for a, b in s["parts"]
        )
        parts_html.append(f"""
<section class="step" id="step-{s['n']}">
  <h3><em>STEP {s['n']:02d}</em> {html.escape(s['title'])}</h3>
  <p class="stepgoal">목표 — {html.escape(ANSWER[s['n']])}</p>
  <div class="ask"><b>Claude Code 에 입력한 프롬프트</b><p>{html.escape(s['asks'])}</p></div>
  <ul class="parts">{pli}</ul>
  {shot}
  <div class="key"><b>이 단계에서 배울 것</b>{html.escape(s['key'])}</div>
</section>""")

    table_rows = "".join(
        f"<tr><td>STEP {s['n']}</td><td><code>{html.escape(p)}</code></td></tr>"
        for s in STEPS for p, _ in s["parts"]
    )

    return f"""<!doctype html>
<html lang="ko"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Claude Code 템플릿 실전 가이드 — 할 일 앱 만들기</title>
<style>{CSS}</style>
</head><body>

<header>
  <h1>템플릿을 쓰는 법 — 할 일 앱 만들기</h1>
  <p>`template/claude/` 의 Claude Code 설정을 실제로 굴려 보는 6단계 기록입니다.
     각 단계의 터미널 화면은 <code>example/claude/run-demo.sh</code> 를 실행해 실제로 만들어졌습니다.</p>
  <div class="badges">
    <span class="badge"><b>6</b> 단계</span>
    <span class="badge">스킬 <b>86</b></span>
    <span class="badge">에이전트 <b>9</b></span>
    <span class="badge">명령 <b>6</b></span>
    <span class="badge">훅 <b>4</b></span>
    <span class="badge">녹화 <b>{total_done}/6</b></span>
  </div>
</header>

<div class="wrap">
  <nav>
    <h2>단계</h2>
    <ol>{''.join(nav_html)}</ol>
  </nav>
  <main>{''.join(parts_html)}

  <section class="step" id="map">
    <h3><em>요약</em> 템플릿 요소가 쓰인 지점</h3>
    <p class="stepgoal">6단계에서 실제로 건드린 템플릿 파일만 추렸다.</p>
    <div class="steps">
      <h4>단계 → 사용한 파일</h4>
      <table>{table_rows}</table>
    </div>
    <div class="key" style="margin-top:16px"><b>다시 실행</b>
      <code>./example/run-demo.sh</code> 를 돌리면 <code>example/claude/todo-app/</code> 이 지워지고
      6단계가 처음부터 다시 실행되며 이 문서가 함께 갱신됩니다.
      <code>--keep</code> 를 붙이면 앱은 남기고 단계만 재실행합니다.</div>
  </section>
  </main>
</div>

<footer>
  <code>template/claude/</code> = ChrisWiles/claude-code-showcase · nidhinjs/prompt-master · zebbern/claude-code-guide 병합본<br>
  이 문서는 <code>example/claude/logs/</code> 의 실제 실행 로그에서 생성됩니다.
</footer>
{JS}
</body></html>"""


if __name__ == "__main__":
    OUT.write_text(build(), encoding="utf-8")
    n = len(list(LOG_DIR.glob("*.log"))) if LOG_DIR.exists() else 0
    size = OUT.stat().st_size / 1024
    print(f"written {OUT} ({size:.0f} KB, {n} logs)")