# SPAI Local Guard (pre-push + Claude Code hook) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a two-layer local guard — a git `pre-push` hook installed by `github-sync` (all CLIs and humans) plus a Claude Code plugin PreToolUse hook (blocks `--no-verify` bypass) — that blocks force pushes, protected-branch deletion, and direct `main` pushes.

**Architecture:** The git hook's single source of truth is a fenced script block inside `skills/github-sync/SKILL.md`; the skill writes it to `.git/hooks/pre-push` during sync, `spai-doctor` diagnoses it by marker. The Claude Code hook lives as real files under a new repo-root `hooks/` directory and is copied into the plugin payload by `build-dist.sh`; the plugin host owns its lifecycle. Spec: `docs/superpowers/specs/2026-08-12-pre-push-guard-design.md`.

**Tech Stack:** POSIX sh, git `pre-push` hook stdin protocol (`<local ref> <local sha> <remote ref> <remote sha>` per line), Claude Code plugin `hooks/hooks.json` (PreToolUse, exit code 2 blocks with stderr fed back), `jq` optional with raw fallback.

## Global Constraints

- Branch `feature/pre-push-guard` (exists, tracks `origin/develop`); finish with `git merge --squash` into `develop`, one `feat:` commit, push. No force push, never `--no-verify`.
- Skill bodies and hook scripts are English; user-facing docs Korean. Generic placeholders only (`your-account`, no local paths).
- Version markers are exact: git hook line 2 `# spai:pre-push v1`, Claude hook line 2 `# spai:guard-push v1`.
- Guard verdicts are **fail-open**: when a case cannot be judged (unknown remote object, unparseable input), allow — git itself, the git hook (for the Claude layer), and server-side protection are the backstops. Blocks must print the violated rule and the correct procedure.
- `dist/` is generated only via `sh scripts/build-dist.sh`; regenerate once in Task 4, never hand-edit.
- `.claude/skills/` carries unprefixed copies of `develop-task-flow`, `github-release`, `github-sync`, `readme` (no `spai-doctor` there — keep that pattern); `.agents/skills/` carries `spai-` prefixed copies of all skills, byte-identical to `dist/codex` payloads.

---

### Task 1: git pre-push guard script + `github-sync` skill procedure

**Files:**
- Modify: `skills/github-sync/SKILL.md` (Scope list, Phase Rules list, Safety Rules, Procedure, Final Report)

**Interfaces:**
- Produces: the canonical guard script (below) and the install procedure. Task 3 (doctor) checks marker `# spai:pre-push v` and the strings `merge-base --is-ancestor`, `refs/heads/main`. Task 6 installs and tests it.

The canonical script (referenced below as THE GUARD SCRIPT):

```sh
#!/bin/sh
# spai:pre-push v1
# SPAI local guard. Blocks force pushes to and deletion of main/develop, and
# direct pushes to main that do not come from develop. Server-side branch
# protection remains the final defense. Do not bypass with --no-verify.

zero=0000000000000000000000000000000000000000

while read -r local_ref local_sha remote_ref remote_sha; do
  case "$remote_ref" in
    refs/heads/main|refs/heads/develop) ;;
    *) continue ;;
  esac

  if [ "$local_sha" = "$zero" ]; then
    echo "spai pre-push: deleting $remote_ref is blocked. Protected branches are never deleted." >&2
    exit 1
  fi

  if [ "$remote_ref" = "refs/heads/main" ] && [ "$local_ref" != "refs/heads/develop" ]; then
    echo "spai pre-push: direct push to main is blocked. Release with: git push origin develop:main" >&2
    exit 1
  fi

  if [ "$remote_sha" != "$zero" ] && git cat-file -e "$remote_sha" 2>/dev/null; then
    if ! git merge-base --is-ancestor "$remote_sha" "$local_sha"; then
      echo "spai pre-push: non-fast-forward push to $remote_ref is blocked. Never force push a protected branch." >&2
      exit 1
    fi
  fi
done

exit 0
```

Design notes baked into the script: deletion is judged by zero local sha; force is judged by ancestry, not by the `--force` flag (the flag never reaches the hook); an unknown `remote_sha` object passes (fail-open — git rejects stale non-ff pushes on its own and the server blocks forced ones); tag pushes and feature branches fall through the `case`.

- [ ] **Step 1: Unit-test the script before embedding it**

```bash
cat > /tmp/spai-guard-test.sh <<'HOOK'
<THE GUARD SCRIPT — paste the exact content from above>
HOOK
chmod +x /tmp/spai-guard-test.sh
cd /tmp && git init -q spai-guard-fixture && cd spai-guard-fixture
git commit --allow-empty -q -m one && old=$(git rev-parse HEAD)
git commit --allow-empty -q -m two && new=$(git rev-parse HEAD)

t() { printf '%s\n' "$1" | /tmp/spai-guard-test.sh >/dev/null 2>&1; echo "$?"; }
echo "delete-develop  $(t "refs/heads/develop $(printf '%040d' 0) refs/heads/develop $new")"
echo "main-from-feat  $(t "refs/heads/feature/x $new refs/heads/main $old")"
echo "force-develop   $(t "refs/heads/develop $old refs/heads/develop $new")"
echo "ff-develop      $(t "refs/heads/develop $new refs/heads/develop $old")"
echo "release-ff      $(t "refs/heads/develop $new refs/heads/main $old")"
echo "feature-push    $(t "refs/heads/feature/x $new refs/heads/feature/x $old")"
```

Run it. Expected: `delete-develop 1`, `main-from-feat 1`, `force-develop 1` (old is not a descendant of new — remote `$new` is not an ancestor of local `$old`), `ff-develop 0`, `release-ff 0`, `feature-push 0`. Any other output: fix the script before touching the skill.

- [ ] **Step 2: Embed the script and procedure in `skills/github-sync/SKILL.md`**

Scope list — after the branch-protection bullet (`- Branch protection for ...`), add:

```markdown
- Local guard: a git `pre-push` hook that blocks force pushes to and deletion of `main`/`develop` and restricts direct `main` pushes to the release fast-forward (`develop:main`). Local defense only; server-side protection stays the final barrier.
```

Phase Rules — replace the four-item list with:

```markdown
1. Inspect repository, working tree, remotes, and `gh` access.
2. Verify or create `develop` from `main`.
3. Apply branch protection.
4. Install or update the local pre-push guard.
5. Validate and report.
```

Safety Rules — add:

```markdown
- Never overwrite a user-authored `.git/hooks/pre-push`; replace it only with explicit confirmation and a `.bak` backup.
- Do not configure `core.hooksPath`; it would disable the user's other hooks.
```

Procedure — after step 6 (protection), insert step 7 and renumber the legacy-drafter step to 8:

````markdown
7. Install or update the local pre-push guard at `.git/hooks/pre-push`:
   - Skip with a pass log when the directory is not a git repository.
   - If the file is missing, write the script below verbatim and `chmod +x` it.
   - If the file exists and line 2 matches `# spai:pre-push v<N>`: rewrite it only when `<N>` is lower than the version below (idempotent).
   - If the file exists without that marker, it is the user's hook: stop this step, report it, and replace it only with explicit confirmation, keeping a `.bak` backup.
   - Never bypass the installed hook with `--no-verify`.

   ```sh
   <THE GUARD SCRIPT — embedded verbatim>
   ```
````

Final Report — add `- Local pre-push guard: installed | updated | already current | blocked by user hook` to the list.

- [ ] **Step 3: Verify the skill file**

Run: `grep -c '# spai:pre-push v1' skills/github-sync/SKILL.md && grep -c 'merge-base --is-ancestor' skills/github-sync/SKILL.md`
Expected: `1` and `1`.

- [ ] **Step 4: Commit**

```bash
git add skills/github-sync/SKILL.md
git commit -m "feat: install a pre-push guard through github-sync"
```

---

### Task 2: Claude Code plugin hook

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/guard-push.sh`
- Modify: `scripts/build-dist.sh` (`build_claude_plugin()`)
- Modify: `scripts/validate-dist.sh` (new checks near the plugin checks)

**Interfaces:**
- Produces: `dist/claude-code-plugin/spai/hooks/{hooks.json,guard-push.sh}` after the Task 4 rebuild. Task 6 runs the stdin test matrix below.

- [ ] **Step 1: Write `hooks/hooks.json`**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard-push.sh\""
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Write `hooks/guard-push.sh`**

```sh
#!/bin/sh
# spai:guard-push v1
# Claude Code PreToolUse hook (matcher: Bash). Blocks git push commands that
# violate the SPAI branch model before they run, including --no-verify
# attempts that would bypass the git pre-push guard. Uncertain input passes
# (fail-open): the git hook and server-side protection are the backstops.
# Exit 2 blocks the tool call; stderr is shown to the model.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
  [ -n "$cmd" ] || exit 0
else
  cmd=$input
fi

case "$cmd" in
  *git*push*) ;;
  *) exit 0 ;;
esac

deny() {
  printf '%s\n' "$1" >&2
  exit 2
}

touches_protected() {
  printf '%s' "$cmd" | grep -qE '(^|[^A-Za-z0-9_/-])(main|develop)([^A-Za-z0-9_/-]|$)'
}

if printf '%s' "$cmd" | grep -qE '(--force([^-]|$)|--force-with-lease|(^|[[:space:]])-f([[:space:]]|$))' && touches_protected; then
  deny "spai guard: force push touching main/develop is blocked. Never force push a protected branch."
fi

if printf '%s' "$cmd" | grep -qE '([[:space:]]:(main|develop)([[:space:]]|$)|--delete[[:space:]].*(main|develop))'; then
  deny "spai guard: deleting a protected branch is blocked."
fi

if printf '%s' "$cmd" | grep -qE '(^|[[:space:]:])main([[:space:]]|$)' \
  && ! printf '%s' "$cmd" | grep -qE 'develop:main'; then
  deny "spai guard: direct push to main is blocked. Release with: git push origin develop:main"
fi

if printf '%s' "$cmd" | grep -qE '(--no-verify)' && touches_protected; then
  deny "spai guard: --no-verify on a protected-branch push is blocked. The pre-push guard must run."
fi

exit 0
```

Then: `chmod +x hooks/guard-push.sh`

- [ ] **Step 3: Unit-test the hook with the stdin matrix**

```bash
g() { printf '{"tool_input":{"command":"%s"}}' "$1" | sh hooks/guard-push.sh >/dev/null 2>&1; echo "$?"; }
echo "force-develop   $(g 'git push --force origin develop')"
echo "delete-develop  $(g 'git push origin :develop')"
echo "head-to-main    $(g 'git push origin HEAD:main')"
echo "push-main       $(g 'git push origin main')"
echo "no-verify       $(g 'git push --no-verify origin develop')"
echo "release-ff      $(g 'git push origin develop:main')"
echo "feature-push    $(g 'git push origin feature/x')"
echo "force-feature   $(g 'git push --force origin feature/x')"
echo "non-git         $(g 'ls -la')"
```

Expected: first five print `2`; last four print `0`. Fix patterns until exact.

- [ ] **Step 4: Wire the build and the validator**

`scripts/build-dist.sh`, inside `build_claude_plugin()` right before the `for skill in $SKILLS; do` loop, add:

```sh
  mkdir -p "$plugin_root/hooks"
  cp hooks/hooks.json "$plugin_root/hooks/hooks.json"
  cp hooks/guard-push.sh "$plugin_root/hooks/guard-push.sh"
  chmod +x "$plugin_root/hooks/guard-push.sh"
```

`scripts/validate-dist.sh`, after the `plugin.json` checks (around line 92-95), add:

```sh
require_file "dist/claude-code-plugin/spai/hooks/hooks.json"
require_file "dist/claude-code-plugin/spai/hooks/guard-push.sh"
require_text "dist/claude-code-plugin/spai/hooks/hooks.json" '"PreToolUse"'
require_text "dist/claude-code-plugin/spai/hooks/hooks.json" 'CLAUDE_PLUGIN_ROOT'
require_text "dist/claude-code-plugin/spai/hooks/guard-push.sh" "spai:guard-push v1"
require_text "dist/claude-code-plugin/spai/skills/github-sync/SKILL.md" "spai:pre-push v1"
require_text "dist/codex/.agents/skills/spai-github-sync/SKILL.md" "spai:pre-push v1"
require_text "dist/antigravity/.agents/skills/spai-github-sync/SKILL.md" "spai:pre-push v1"
```

- [ ] **Step 5: Commit**

```bash
git add hooks scripts/build-dist.sh scripts/validate-dist.sh
git commit -m "feat: add claude code plugin guard hook and dist wiring"
```

---

### Task 3: doctor diagnosis + no-bypass safety rules

**Files:**
- Modify: `skills/spai-doctor/SKILL.md` (Checks list, Final Report template, fix-owner list)
- Modify: `skills/develop-task-flow/SKILL.md` (Safety Rules)
- Modify: `skills/github-release/SKILL.md` (Safety Rules)

**Interfaces:**
- Consumes: marker `# spai:pre-push v1` and rule strings from Task 1.

- [ ] **Step 1: Add doctor check 8**

In `skills/spai-doctor/SKILL.md`, after check 7 (Legacy leftovers), add:

```markdown
8. **Local pre-push guard**: inspect `.git/hooks/pre-push`.
   - Missing file, or line 2 not matching `# spai:pre-push v<N>`: the guard is not installed (an unmarked file is the user's own hook — never report it as drift).
   - Marked but `<N>` lower than the latest guard version (`v1`): outdated.
   - Marked but missing `merge-base --is-ancestor` or `refs/heads/main`, or not executable: locally modified or broken.
   - Fix owner is `github-sync`; report, never modify.
```

In the Final Report template, after the `### 레거시` section, add:

```markdown
### 로컬 가드
- pre-push: OK vN | 미설치 | 구버전 (vN → vM) | 수정됨/실행권한 없음 | 사용자 훅 존재
```

In the Procedure fix-owner list, add: `- local guard missing, outdated, or modified → `github-sync``. Also change "Run checks 1–7 in order" to "Run checks 1–8 in order".

- [ ] **Step 2: Add the no-bypass rule to both flow skills**

`skills/develop-task-flow/SKILL.md` Safety Rules, after `- Do not force push.`:

```markdown
- Do not bypass git hooks: never pass `--no-verify` to `git push`.
```

`skills/github-release/SKILL.md` Safety Rules, after `- Do not force push.`: same line.

- [ ] **Step 3: Verify**

Run: `grep -c 'spai:pre-push' skills/spai-doctor/SKILL.md; grep -c -- '--no-verify' skills/develop-task-flow/SKILL.md skills/github-release/SKILL.md`
Expected: `1` for the doctor file, `1` per flow skill file.

- [ ] **Step 4: Commit**

```bash
git add skills/spai-doctor/SKILL.md skills/develop-task-flow/SKILL.md skills/github-release/SKILL.md
git commit -m "feat: diagnose the local guard and forbid hook bypass"
```

---

### Task 4: rebuild dist + sync all skill copies

**Files:**
- Regenerate: `dist/`
- Modify: `.agents/skills/spai-github-sync/SKILL.md`, `.agents/skills/spai-doctor/SKILL.md`, `.agents/skills/spai-develop-task-flow/SKILL.md`, `.agents/skills/spai-github-release/SKILL.md`
- Modify: `.claude/skills/github-sync/SKILL.md`, `.claude/skills/develop-task-flow/SKILL.md`, `.claude/skills/github-release/SKILL.md`

**Interfaces:**
- Consumes: all source edits from Tasks 1-3.

- [ ] **Step 1: Rebuild and validate**

Run: `sh scripts/build-dist.sh && sh scripts/validate-dist.sh`
Expected: file list includes `dist/claude-code-plugin/spai/hooks/hooks.json` and `guard-push.sh`; `dist validation ok`.

- [ ] **Step 2: Sync copies**

```bash
for s in github-sync doctor develop-task-flow github-release; do
  case "$s" in doctor) src=spai-doctor ;; *) src=spai-$s ;; esac
  cp "dist/codex/.agents/skills/$src/SKILL.md" ".agents/skills/$src/SKILL.md"
done
for s in github-sync develop-task-flow github-release; do
  cp "skills/$s/SKILL.md" ".claude/skills/$s/SKILL.md"
done
```

- [ ] **Step 3: Verify copies byte-identical**

```bash
cmp .agents/skills/spai-github-sync/SKILL.md dist/codex/.agents/skills/spai-github-sync/SKILL.md \
  && cmp .agents/skills/spai-doctor/SKILL.md dist/codex/.agents/skills/spai-doctor/SKILL.md \
  && cmp .agents/skills/spai-develop-task-flow/SKILL.md dist/codex/.agents/skills/spai-develop-task-flow/SKILL.md \
  && cmp .agents/skills/spai-github-release/SKILL.md dist/codex/.agents/skills/spai-github-release/SKILL.md \
  && cmp .claude/skills/github-sync/SKILL.md skills/github-sync/SKILL.md \
  && cmp .claude/skills/develop-task-flow/SKILL.md skills/develop-task-flow/SKILL.md \
  && cmp .claude/skills/github-release/SKILL.md skills/github-release/SKILL.md \
  && echo copies-ok
```

Expected: `copies-ok`

- [ ] **Step 4: Commit**

```bash
git add dist .agents .claude
git commit -m "feat: regenerate dist and sync guard changes into skill copies"
```

---

### Task 5: documentation

**Files:**
- Modify: `README.md` (제공 스킬 표 `github-sync` row)
- Modify: `docs/github-repository-settings.md` (append section)
- Modify: `docs/roadmap.md` (현재 제공 + 방향 후보 표)

**Interfaces:**
- Consumes: names/behavior from Tasks 1-2. No later task depends on this one.

- [ ] **Step 1: README.md** — replace the `github-sync` table row:

```markdown
| `github-sync` | `main`/`develop` 브랜치·branch protection 동기화, 로컬 `pre-push` 가드 설치 |
```

- [ ] **Step 2: docs/github-repository-settings.md** — append at the end:

```markdown
## 로컬 pre-push 가드

서버측 branch protection과 별개로, `github-sync`가 `.git/hooks/pre-push`에 로컬 가드를 설치합니다. clone마다 로컬에만 존재하므로 새 clone에서는 `github-sync`를 다시 실행해야 합니다.

- `main`/`develop` 대상 force push(non-fast-forward) 차단
- `main`/`develop` 원격 삭제 차단
- `develop:main` fast-forward(릴리즈) 이외의 `main` 직접 push 차단

`--no-verify`로 우회할 수 있는 것이 git hook의 한계입니다. SPAI 스킬은 우회를 금지하며, Claude Code에서는 `spai` 플러그인의 PreToolUse hook이 `--no-verify`를 포함한 위반 push 명령을 실행 전에 차단합니다. 최종 방어는 서버측 branch protection입니다. 진단은 `spai-doctor`, 재설치·갱신은 `github-sync`가 담당합니다.
```

- [ ] **Step 3: docs/roadmap.md** — two edits.

현재 제공 list, after the `- 문서 스킬 1종: ...` line:

```markdown
- 로컬 가드 2층: `github-sync`가 설치하는 git `pre-push` hook(전 CLI 공통) + Claude Code 플러그인 PreToolUse hook(`--no-verify` 우회 차단)
```

방향 후보 표, after the `**D. engine/content 분리 (registry)**` row:

```markdown
| **E. Codex/Antigravity 네이티브 hook** | git pre-push 가드를 두 CLI의 네이티브 PreToolUse hook으로도 제공 (Codex `hooks.json`은 experimental·기본 비활성, Antigravity는 사용자 소유 설정 파일 편집 필요) | 해당 CLI hook의 GA/안정화 + git hook으로 못 막는 실사례 발생 |
```

- [ ] **Step 4: Verify and commit**

Run: `sh scripts/validate-dist.sh` — expected `dist validation ok`.

```bash
git add README.md docs/github-repository-settings.md docs/roadmap.md
git commit -m "docs: describe the local guard layers"
```

---

### Task 6: end-to-end verification in this repository

**Files:**
- Create (untracked, runtime): `.git/hooks/pre-push` in this repository

**Interfaces:**
- Consumes: THE GUARD SCRIPT (Task 1) via the `github-sync` procedure; the Task 2 stdin matrix.

- [ ] **Step 1: Install per the new `github-sync` step 7** — this repo has no `.git/hooks/pre-push`, so write the script from `skills/github-sync/SKILL.md` verbatim and `chmod +x` it.

- [ ] **Step 2: Re-run the Task 1 stdin matrix against the installed hook** (`.git/hooks/pre-push` instead of `/tmp/spai-guard-test.sh`, run from the repo root with two real commits: `old=$(git rev-parse HEAD~1)`, `new=$(git rev-parse HEAD)`). Expected: identical verdicts (`1,1,1,0,0,0`).

- [ ] **Step 3: Live smoke test** — `git push --dry-run origin develop` from the repo root. Expected: no guard output, exit 0 (up-to-date or fast-forward pass).

- [ ] **Step 4: Re-run the Task 2 matrix** — `sh hooks/guard-push.sh` cases must still print `2,2,2,2,2,0,0,0,0`.

- [ ] **Step 5: Doctor check dry-run** — follow the new check 8 manually: line 2 marker (`sed -n 2p .git/hooks/pre-push`) is `# spai:pre-push v1`, file executable, rule strings present. Expected: "OK v1".

No commit — `.git/hooks/` is never tracked.

---

### Task 7: squash merge into develop and push

- [ ] **Step 1: Verify clean and validated**

Run: `git status --short && sh scripts/validate-dist.sh`
Expected: empty status, `dist validation ok`.

- [ ] **Step 2: Squash merge and commit**

```bash
git switch develop
git pull --ff-only origin develop
git merge --squash feature/pre-push-guard
git commit -m "feat: add a two-layer local push guard

- \`github-sync\`가 git \`pre-push\` hook을 설치합니다: \`main\`/\`develop\` 대상 force push와 원격 삭제를 차단하고, \`main\` 직접 push는 릴리즈 fast-forward(\`develop:main\`)만 허용합니다. 어느 CLI가 실행하든, 사람이 직접 push하든 동일하게 작동합니다.
- Claude Code에는 \`spai\` 플러그인에 PreToolUse hook이 추가되어 \`--no-verify\` 우회를 포함한 위반 push 명령을 실행 전에 차단합니다.
- \`spai-doctor\`가 가드 설치 상태(마커 버전·수정·실행 권한)를 진단하고, \`develop-task-flow\`·\`github-release\`에 git hook 우회 금지 규칙이 추가되었습니다.
- 기존 \`.git/hooks/pre-push\`(사용자 훅)는 확인 없이 덮어쓰지 않으며, 서버측 branch protection은 최종 방어로 유지됩니다."
```

- [ ] **Step 3: Push and verify**

Run: `git push origin develop && git log origin/develop --oneline -1`
Expected: fast-forward push (the freshly installed guard itself passes it), squash commit on top.

Then stop and ask the user whether to release (grade would be `minor` → `v0.5.0`).

---

## After the plan

Release only on explicit user confirmation. Grade `minor`: new capability; existing installs converge by re-running `spai-update`/`github-sync` (Claude Code plugin hook arrives via plugin update) — no Migration blocks needed.
