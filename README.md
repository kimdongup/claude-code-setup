# Claude Code 설정 컬렉션

> 3개의 검증된 Claude Code 공식 문서 리소스를 병합하여 만든 실전 설정 컬렉션입니다. 59개 URL 중 L10 등급 3개를 선별하여 실제 사용할 수 있는 환경으로 구성했습니다.

## 📋 출처 (Level 10 인증)

| # | 출처 | 카테고리 | 주요 내용 |
|---|------|----------|----------|
| 1 | [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | 설정 (Config) | settings.json, hooks, agents, commands, skills, MCP, GitHub Actions |
| 2 | [nidhinjs/prompt-master](https://github.com/nidhinjs/prompt-master) | 메모리/프롬프트 | SKILL.md 작성법, 프롬프트 패턴, 템플릿 |
| 3 | [zebbern/claude-code-guide](https://github.com/zebbern/claude-code-guide) | 시작 가이드 (Start) | 80개+ 스킬, 9개 에이전트, CLAUDE.md 가이드 |

## 🚀 빠른 시작

### 1. 이 저장소를 프로젝트에 적용

```bash
# 기존 프로젝트에 복사
mkdir -p my-project/.claude
cp -r .claude/* my-project/.claude/
cp CLAUDE.md my-project/CLAUDE.md
cp .mcp.json my-project/.mcp.json  # 선택사항 (MCP 서버 설정)
```

### 2. 또는 새 프로젝트에서 시작

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-setup.git my-project
cd my-project
```

## 📦 포함된 구성 요소

| 항목 | 개수 | 설명 |
|------|------|------|
| **스킬 (Skills)** | 86개 | 도메인 지식, 테스트, 디버깅, 보안, API, 데이터베이스 등 |
| **에이전트 (Agents)** | 9개 | 코드 리뷰, 솔루션 아키텍트, 보안 리뷰, 디버거 등 |
| **슬래시 명령 (Commands)** | 6개 | PR 리뷰, 온보딩, 티켓, 코드 품질, 문서 동기화 등 |
| **훅 (Hooks)** | 4개 | 스킬 평가, 자동 포맷팅, 테스트 실행 등 |
| **GitHub Actions** | 4개 | PR 리뷰, 품질 검토, 문서 동기화, 의존성 감사 |

## 📁 디렉토리 구조

```
claude-code-setup/
├── CLAUDE.md              # 프로젝트 메모리 (프롬프트 가이드 포함)
├── .claude/
│   ├── settings.json      # 훅, 환경변수, 권한 설정
│   ├── settings.md        # 훅 설명서
│   ├── .gitignore         # 로컬 파일 무시 목록
│   ├── .mcp.json          # MCP 서버 설정
│   ├── agents/            # 9개 전문 에이전트
│   ├── commands/          # 6개 슬래시 명령
│   ├── hooks/             # 4개 자동화 훅
│   ├── skills/            # 86개 도메인 지식 스킬
│   └── rules/             # 모듈식 규칙
├── .github/
│   └── workflows/         # 4개 CI/CD 워크플로
├── LICENSE
└── README.md
```

## 🎯 주요 기능

### 설정 (Config) - ChrisWiles/claude-code-showcase
- **settings.json**: 훅, 환경변수, 권한 설정
- **hooks**: 스킬 평가, 자동 포맷팅, 테스트 실행, 타입 체크
- **agents**: 코드 리뷰, GitHub 워크플로 에이전트
- **commands**: 온보딩, PR 리뷰, 티켓 워크플로 등
- **MCP**: JIRA, GitHub, Slack 등 연동 서버 설정
- **GitHub Actions**: 자동 PR 리뷰, 주간 품질 검토 등

### 메모리/프롬프트 - nidhinjs/prompt-master
- **SKILL.md**: 프롬프트 작성 가이드라인
- **references/templates.md**: 프롬프트 템플릿 모음
- **references/patterns.md**: 프롬프트 패턴 모음

### 시작 가이드 (Start) - zebbern/claude-code-guide
- **86개 스킬**: 보안, 데이터베이스, API, 프론트엔드, 백엔드 등
- **9개 에이전트**: 코드 리뷰, 아키텍트, 디버거, 연구원 등
- **CLAUDE.md**: 프로젝트 메모리 작성 가이드

## 🛠️ 사용 예시

### 코드 리뷰 에이전트 호출
```
@code-reviewer 이 PR을 리뷰해줘
```

### 테스트 스킬 사용
```
새로운 API 엔드포인트에 대한 테스트를 작성해줘. testing-patterns 스킬을 사용해.
```

### 티켓 워크플로
```
/ticket PROJ-123
# JIRA 티켓을 읽고, 코드를 구현하고, 상태를 업데이트합니다
```

## 📜 라이선스

MIT 라이선스 - 자유롭게 사용, 수정, 배포할 수 있습니다.

## 🤝 기여

이 저장소는 3개의 오픈소스 Claude Code 설정 저장소를 병합한 것입니다. 새로운 스킬, 에이전트, 혹은 개선 제안은 Pull Request로 환영합니다.

## 🔗 관련 링크

- [Claude Code 공식 문서](https://code.claude.com/docs/en/overview)
- [Anthropic 공식 문서](https://docs.anthropic.com)
- [원본 저장소 1](https://github.com/ChrisWiles/claude-code-showcase)
- [원본 저장소 2](https://github.com/nidhinjs/prompt-master)
- [원본 저장소 3](https://github.com/zebbern/claude-code-guide)
