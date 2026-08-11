---
name: spai-doctor
description: "Use when diagnosing the SPAI installation in this repository: compare the installed version stamp with the latest release, verify the Claude Code plugin is registered and enabled, detect locally modified skill files for codex and antigravity, verify branch protection, and report legacy leftovers. Read-only; fixes are delegated to spai-update and github-sync."
---

# SPAI Doctor

Use this repository skill to diagnose the installed SPAI state. This skill never modifies files or settings.

## Distribution Model

- Claude Code installs SPAI as the `spai` plugin. Its skills are namespaced by the host as `/spai:<skill>` and live under the plugin directory, never under `.claude/skills`.
- Codex and Antigravity have no plugin system. They install `spai-` prefixed skill directories under `.agents/skills`.
- Every target keeps a `<!-- spai:version ... -->` stamp inside the SPAI managed block of `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`.

## Checks

1. **Version**: read the installed stamp (`grep -h "spai:version" CLAUDE.md AGENTS.md GEMINI.md 2>/dev/null | head -n 1`) and compare with the latest release tag (`gh api repos/0x0w1/spai/releases/latest --jq .tag_name`). Also read `skills=` from the stamp; a stamp without it means the full default skill set, and a missing stamp means an install without a version stamp.
2. **Claude Code plugin**: only when `CLAUDE.md` carries the SPAI managed block.
   - `claude plugin list` (or the `enabledPlugins` entry in `.claude/settings.json`) must show `spai@spai`.
   - `.claude/settings.json` should carry the marketplace under `extraKnownMarketplaces`. For project scope this is what shares the plugin with collaborators.
   - Report a missing entry with the exact fix: `claude plugin marketplace add 0x0w1/spai` then `claude plugin install spai@spai --scope project`.
   - If the `claude` CLI is unavailable, report the check as skipped.
3. **Drift** (codex and antigravity only; the Claude Code plugin is updated by the host): for each installed skill file, compare with the payload of the stamped version.
   - codex: `curl -fsSL https://raw.githubusercontent.com/0x0w1/spai/<stamp>/dist/codex/.agents/skills/spai-<skill>/SKILL.md | cmp -s - .agents/skills/spai-<skill>/SKILL.md`
   - antigravity: same with `dist/antigravity/.agents/skills/spai-<skill>/SKILL.md`
   - A `cmp` mismatch means the file was locally modified or partially updated. If the stamp is `main` or `custom`, drift cannot be judged against a fixed payload; report that instead.
4. **Branch protection**: `gh api repos/<owner>/<repo>/branches/<branch>/protection` for `main` and `develop`. Expected on both branches: no required pull request reviews, no required status checks, `allow_force_pushes.enabled == false`, `allow_deletions.enabled == false`. A 404 means no protection is configured.
5. **Branch state**: after `git fetch origin --prune`, run `git rev-list --left-right --count origin/main...origin/develop`. If `main` is ahead of `develop` (left count > 0), the next release cannot fast-forward; report it.
6. **Legacy leftovers** (report existence only):
   - unprefixed SPAI skill directories from an installer-copy era: `.claude/skills/{github-sync,github-release,develop-task-flow,spai-update,spai-doctor}/`, and the same names under `.agents/skills/`. These are superseded by the plugin and the `spai-` prefixed directories.
   - `.github/drafter-config.yaml`, `.github/workflows/drafter.yaml`, `.github/PULL_REQUEST_TEMPLATE.md`
   - labels `patch`, `minor`, `major`, `enhancement`, `fix`, `chore` (`gh label list`)
   - leftover backups: `find . -name "*.bak" -not -path "./.git/*"`

## Safety Rules

- Read-only: do not modify files, settings, branches, or labels.
- Do not run the installer or any `claude plugin` command that changes state; recommend `spai-update` instead.
- Report the exact command for each recommended fix, but do not execute it.
- Never report a skill the user wrote as a SPAI problem. SPAI only owns the `spai` plugin and `spai-` prefixed directories.
- Preserve unrelated user changes.

## Procedure

1. Confirm context: `git rev-parse --is-inside-work-tree`, `gh repo view`, `gh auth status`, `command -v claude`. If a tool is unavailable, run only the checks that do not need it and list the skipped checks in the report.
2. Run checks 1–6 in order and collect the results.
3. Compose the report. For every finding, name the fix owner:
   - version behind, drifted files, or missing plugin → `spai-update`
   - protection mismatch or legacy leftovers → `github-sync` (deletions only with explicit confirmation)
   - branch state divergence → stop releases and reconcile manually; never force-push.

## Final Report

```md
## SPAI 진단 보고서

### 버전
- 설치: <stamp> / 최신: <latest> → 최신 여부

### Claude Code 플러그인
- 등록/활성: OK | 누락 항목과 복구 명령

### 드리프트 (codex/antigravity)
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
