---
name: spai-doctor
description: "Use when diagnosing the SPAI installation in this repository: compare the installed version stamp with the latest release, detect locally modified (drifted) skill files, verify branch protection, and report legacy leftovers. Read-only; fixes are delegated to spai-update and github-sync."
---

# SPAI Doctor

Use this repository skill to diagnose the installed SPAI state. This skill never modifies files or settings.

## Checks

1. **Version**: read the installed stamp (`grep -h "spai:version" CLAUDE.md AGENTS.md GEMINI.md 2>/dev/null | head -n 1`) and compare with the latest release tag (`gh api repos/0x0w1/spai/releases/latest --jq .tag_name`). Also read `flow=` and `skills=` from the stamp; a stamp without them means `flow=solo-cli` with the full default skill set, and a missing stamp means an install without a version stamp.
2. **Drift**: for each installed skill file, compare with the payload of the stamped version:
   - claude-code: `curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/<stamp>/dist/claude-code/.claude/skills/<skill>/SKILL.md | cmp -s - .claude/skills/<skill>/SKILL.md`
   - codex: same with `dist/codex/.agents/skills/<skill>/SKILL.md`
   - antigravity: same with `dist/antigravity/.agents/skills/<skill>/SKILL.md`
   - When the stamped flow is not `solo-cli`, compare against `SKILL.<flow>.md` (or `<skill>.<flow>.mdc`) when that variant exists in the payload; fall back to the base file otherwise.
   - A `cmp` mismatch means the file was locally modified or partially updated. If the stamp is `main` or `custom`, drift cannot be judged against a fixed payload; report that instead.
3. **Branch protection**: `gh api repos/<owner>/<repo>/branches/<branch>/protection` for `main` and `develop`. Expected by flow:
   - `solo-cli`: both branches — no required pull request reviews, no required status checks, `allow_force_pushes.enabled == false`, `allow_deletions.enabled == false`.
   - `team-pr`: `develop` must have `required_pull_request_reviews`; `main` must not. Force pushes and deletion blocked on both.
   - A 404 means no protection is configured.
4. **Branch state**: after `git fetch origin --prune`, run `git rev-list --left-right --count origin/main...origin/develop`. If `main` is ahead of `develop` (left count > 0), the next release cannot fast-forward; report it.
5. **Legacy leftovers** (report existence only):
   - `.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, `.github/PULL_REQUEST_TEMPLATE.md`
   - labels `patch`, `minor`, `major`, `enhancement`, `fix`, `chore` (`gh label list`)
   - knowledges leftovers: `.claude/skills/knowledges-quick-ingest/`, `.claude/rules/knowledges-raw-contract.md`, `.claude/guardrails/knowledges-ingest.md`, the same paths under `.agents/`, `.cursor/rules/knowledges-*.mdc`, and a `KNOWLEDGES_ROOT` entry in `.env`
   - leftover backups: `find . -name "*.bak" -not -path "./.git/*"`

## Safety Rules

- Read-only: do not modify files, settings, branches, or labels.
- Do not run the installer; recommend `spai-update` instead.
- Report the exact command for each recommended fix, but do not execute it.
- Preserve unrelated user changes.

## Procedure

1. Confirm context: `git rev-parse --is-inside-work-tree`, `gh repo view`, `gh auth status`. If `gh` is unavailable, run only the local checks (stamp read, local legacy files, backups) and list the skipped checks in the report.
2. Run checks 1–5 in order and collect the results.
3. Compose the report. For every finding, name the fix owner:
   - version behind or drifted files → `spai-update` (re-installs with `*.bak` backups)
   - protection mismatch or legacy leftovers → `github-sync` (deletions only with explicit confirmation)
   - branch state divergence → stop releases and reconcile manually; never force-push.

## Final Report

```md
## SPAI 진단 보고서

### 버전
- 설치: <stamp> / 최신: <latest> → 최신 여부

### 드리프트
- 없음 | 불일치 파일 목록

### 브랜치 보호
- main: OK | 항목별 불일치
- develop: OK | 항목별 불일치

### 브랜치 상태
- OK | main이 N커밋 앞섬 (fast-forward 릴리즈 불가)

### 레거시
- 없음 | 발견 항목 목록

### 권장 조치
- <fix owner>: <명령 또는 스킬>
```
