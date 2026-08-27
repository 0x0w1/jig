#!/usr/bin/env sh
set -eu

INSPECTOR=skills/jig-doctor/scripts/inspect-claude-standalone.sh
TEST_ROOT=$(mktemp -d)
FIXTURES="$TEST_ROOT/fixtures"
OUTPUTS="$TEST_ROOT/outputs"
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
mkdir -p "$FIXTURES" "$OUTPUTS"

extract_contract() {
  sed -n '/^<!-- jig:start installation-inventory -->$/,/^<!-- jig:end installation-inventory -->$/p' "$1"
}

extract_contract skills/jig-update/SKILL.md > "$OUTPUTS/update-contract"
extract_contract skills/jig-doctor/SKILL.md > "$OUTPUTS/doctor-contract"
cmp -s "$OUTPUTS/update-contract" "$OUTPUTS/doctor-contract"
[ "$(grep -c '^| ' "$OUTPUTS/doctor-contract")" -eq 11 ]

write_skill() {
  skill_destination="$1"
  skill_name="$2"
  skill_title="$3"
  mkdir -p "$(dirname "$skill_destination")"
  printf '%s\n' '---' "name: $skill_name" '---' "$skill_title" 'Repository: 0x0w1/jig' \
    > "$skill_destination"
}

write_provenance() {
  provenance_destination="$1"
  provenance_skill="$2"
  provenance_directory="$3"
  printf '%s\n' \
    'format=1' \
    'repository=0x0w1/jig' \
    "skill=$provenance_skill" \
    "directory=$provenance_directory" \
    > "$provenance_destination"
}

write_verified_root() {
  verified_root="$1"
  verified_scope="$2"
  mkdir -p "$verified_root/jig-update" "$verified_root/github-sync"
  write_skill "$verified_root/jig-update/SKILL.md" jig-update '# jig Update'
  write_skill "$verified_root/github-sync/SKILL.md" github-sync '# GitHub Sync'
  write_provenance "$verified_root/jig-update/.jig-provenance" jig-update jig-update
  write_provenance "$verified_root/github-sync/.jig-provenance" github-sync github-sync
  printf '%s\n' \
    'format=1' \
    'repository=0x0w1/jig' \
    'version=v9.9.9' \
    'target=claude-code' \
    "scope=$verified_scope" \
    'skills=jig-update=jig-update,github-sync=github-sync' \
    > "$verified_root/.jig-installation"
}

VERIFIED="$FIXTURES/verified/.claude/skills"
LEGACY="$FIXTURES/legacy/.claude/skills"
PARTIAL="$FIXTURES/partial/.claude/skills"
CONFLICT="$FIXTURES/conflict/.claude/skills"
INVALID="$FIXTURES/invalid/.claude/skills"
NON_OWNED="$FIXTURES/non-owned/.claude/skills"

write_verified_root "$VERIFIED" project
mkdir -p "$LEGACY/jig-update"
write_skill "$LEGACY/jig-update/SKILL.md" jig-update '# jig Update'
mkdir -p "$(dirname "$PARTIAL")" "$(dirname "$CONFLICT")" "$(dirname "$INVALID")"
cp -R "$VERIFIED" "$PARTIAL"
rm "$PARTIAL/github-sync/.jig-provenance"
cp -R "$VERIFIED" "$CONFLICT"
printf '%s\n' \
  'format=1' \
  'repository=another/repository' \
  'skill=github-sync' \
  'directory=github-sync' \
  > "$CONFLICT/github-sync/.jig-provenance"
cp -R "$VERIFIED" "$INVALID"
printf '%s\n' 'unexpected=value' >> "$INVALID/.jig-installation"
mkdir -p "$NON_OWNED/personal-skill"
write_skill "$NON_OWNED/personal-skill/SKILL.md" personal-skill '# Personal Skill'

snapshot() {
  find "$FIXTURES" -type f -exec cksum {} \; | LC_ALL=C sort
}

snapshot > "$OUTPUTS/before"

sh "$INSPECTOR" --root "$VERIFIED" --scope project > "$OUTPUTS/verified"
grep -Fx 'status=verified' "$OUTPUTS/verified" >/dev/null
grep -Fx 'version=v9.9.9' "$OUTPUTS/verified" >/dev/null
grep -Fx 'skills=jig-update=jig-update,github-sync=github-sync' "$OUTPUTS/verified" >/dev/null

sh "$INSPECTOR" --root "$LEGACY" --scope project > "$OUTPUTS/legacy"
grep -Fx 'status=legacy-unledgered' "$OUTPUTS/legacy" >/dev/null
grep -Fx 'version=unknown' "$OUTPUTS/legacy" >/dev/null

sh "$INSPECTOR" --root "$PARTIAL" --scope project > "$OUTPUTS/partial"
grep -Fx 'status=partial' "$OUTPUTS/partial" >/dev/null
grep -Fx 'finding=missing-provenance:github-sync' "$OUTPUTS/partial" >/dev/null

sh "$INSPECTOR" --root "$CONFLICT" --scope project > "$OUTPUTS/conflict"
grep -Fx 'status=provenance-conflict' "$OUTPUTS/conflict" >/dev/null
grep -Fx 'finding=invalid-provenance:github-sync' "$OUTPUTS/conflict" >/dev/null

sh "$INSPECTOR" --root "$INVALID" --scope project > "$OUTPUTS/invalid"
grep -Fx 'status=ledger-invalid' "$OUTPUTS/invalid" >/dev/null

sh "$INSPECTOR" --root "$NON_OWNED" --scope project > "$OUTPUTS/non-owned"
grep -Fx 'status=non-owned' "$OUTPUTS/non-owned" >/dev/null

sh "$INSPECTOR" --root "$FIXTURES/absent/.claude/skills" --scope user > "$OUTPUTS/absent"
grep -Fx 'status=absent' "$OUTPUTS/absent" >/dev/null

snapshot > "$OUTPUTS/after"
cmp -s "$OUTPUTS/before" "$OUTPUTS/after"

printf '%s\n' 'doctor installation inventory tests ok'
