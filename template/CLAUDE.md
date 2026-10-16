# Claude Code 설정 컬렉션

이 저장소는 3개의 검증된 Claude Code 공식 문서 리소스를 병합하여 만든 실전 설정 컬렉션입니다.

## 출처 (Level 10 인증)

| 출처 | 용도 | 주요 내용 |
|------|------|----------|
| [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | 설정 (Config) | settings.json, hooks, agents, commands, skills, MCP, GitHub Actions |
| [nidhinjs/prompt-master](https://github.com/nidhinjs/prompt-master) | 메모리/프롬프트 | SKILL.md 작성법, 프롬프트 패턴, 템플릿 |
| [zebbern/claude-code-guide](https://github.com/zebbern/claude-code-guide) | 시작 가이드 (Start) | 80개+ 스킬, 9개 에이전트, CLAUDE.md 가이드 |

## 빠른 시작

```bash
# 1. 이 저장소를 프로젝트에 복사
git clone https://github.com/YOUR_USERNAME/claude-code-setup.git my-project/.claude

# 2. 또는 기존 프로젝트에 수동 복사
cp -r .claude/* my-project/.claude/
cp CLAUDE.md my-project/CLAUDE.md

# 3. Claude Code 설정 적용
claude mcp add jira npx -y @anthropic/mcp-jira  # 선택사항
```

## 디렉토리 구조

```
your-project/
├── CLAUDE.md              # 프로젝트 기억 (이 파일)
├── .mcp.json              # MCP 서버 설정 (JIRA, GitHub, Slack 등)
├── .claude/
│   ├── settings.json      # 훅, 환경변수, 권한 설정
│   ├── settings.md        # 훅 설명서 (사람이 읽기 쉬운 버전)
│   ├── .gitignore         # 로컬/개인 파일 무시 목록
│   │
│   ├── agents/            # 전문 AI 에이전트 (9개)
│   │   ├── code-reviewer.md        # 코드 리뷰 에이전트
│   │   ├── github-workflow.md      # Git 워크플로 에이전트
│   │   ├── solution-architect.md   # 솔루션 아키텍트 에이전트
│   │   ├── security-reviewer.md    # 보안 리뷰 에이전트
│   │   ├── root-cause-debugger.md  # 근본 원인 디버거
│   │   ├── runtime-verifier.md     # 런타임 검증기
│   │   ├── codebase-mapper.md      # 코드베이스 매퍼
│   │   ├── official-docs-researcher.md  # 공식 문서 연구원
│   │   └── change-implementer.md   # 변경 구현자
│   │
│   ├── commands/          # 슬래시 명령 (6개)
│   │   ├── onboard.md         # 깊은 태스크 탐색
│   │   ├── pr-review.md       # PR 리뷰 워크플로
│   │   ├── pr-summary.md      # PR 요약 생성
│   │   ├── code-quality.md    # 품질 검사
│   │   ├── docs-sync.md       # 문서 동기화
│   │   └── ticket.md          # JIRA/Linear 티켓 워크플로
│   │
│   ├── hooks/             # 훅 스크립트 (4개)
│   │   ├── skill-eval.sh          # 스킬 평가 훅 (셸)
│   │   ├── skill-eval.js          # 스킬 평가 훅 (Node.js)
│   │   ├── skill-rules.json       # 패턴 매칭 규칙
│   │   └── skill-rules.schema.json
│   │
│   ├── skills/            # 도메인 지식 스킬 (86개)
│   │   ├── README.md              # 스킬 개요
│   │   ├── prompt-master/         # 프롬프트 작성 스킬 (핵심)
│   │   ├── testing-patterns/      # 테스트 패턴
│   │   ├── systematic-debugging/  # 체계적 디버깅
│   │   ├── react-ui-patterns/     # React UI 패턴
│   │   ├── graphql-schema/        # GraphQL 스키마
│   │   ├── core-components/       # 디자인 시스템
│   │   └── ... (80개 이상)
│   │
│   └── rules/             # 모듈식 규칙 (선택사항)
│
└── .github/
    └── workflows/
        ├── pr-claude-code-review.yml           # 자동 PR 리뷰
        ├── scheduled-claude-code-quality.yml   # 주간 품질 검토
        ├── scheduled-claude-code-docs-sync.yml # 월간 문서 동기화
        └── scheduled-claude-code-dependency-audit.yml # 이중주기 의존성 감사
```

## 설치 방법

### 방법 1: 기존 프로젝트에 적용

```bash
# 프로젝트 루트에서 실행
mkdir -p .claude
cp -r /path/to/claude-code-setup/.claude/* .claude/
cp /path/to/claude-code-setup/CLAUDE.md ./CLAUDE.md
cp /path/to/claude-code-setup/.mcp.json ./.mcp.json  # 선택사항
```

### 방법 2: 새 프로젝트에서 시작

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-setup.git my-project
cd my-project
# 이제 Claude Code가 이 설정을 자동으로 읽습니다
```

## 핵심 구성 요소

### CLAUDE.md - 프로젝트 기억
Claude Code가 세션 시작 시 자동으로 읽는 프로젝트 메모리 파일입니다. 프로젝트 스택, 코드 스타일, 중요 규칙을 포함합니다.

### .claude/settings.json - 훅 및 환경
자동 포맷팅, 테스트 실행, 타입 체크, Git 분기 보호 등 자동화 훅을 설정합니다.

### .claude/skills/ - 도메인 지식 (86개)
프로젝트별 관례와 패턴을 Claude에게 가르치는 스킬 파일들입니다. 각 스킬은 `SKILL.md` 형식으로 작성됩니다.

### .claude/agents/ - 전문 에이전트 (9개)
특정 목적의 AI 에이전트들입니다. 코드 리뷰, 보안, 아키텍처, 디버깅 등 다양한 역할을 수행합니다.

### .claude/hooks/ - 수명 주기 자동화 (4개)
프롬프트 제출 전후, 도구 실행 전후에 실행되는 자동화 스크립트입니다. 스킬 자동 추천, 포맷팅, 테스트 실행 등을 포함합니다.

### .claude/commands/ - 슬래시 명령 (6개)
`/pr-review`, `/ticket`, `/onboard` 등 사용자 정의 슬래시 명령입니다.

## 기여하기

이 저장소는 3개의 우수한 Claude Code 설정 저장소를 병합한 것입니다. 개선 제안이나 새로운 스킬/에이전트 추가는 Pull Request로 접수해 주세요.

## 라이선스

MIT 라이선스 - 자유롭게 사용하고 수정하세요.
