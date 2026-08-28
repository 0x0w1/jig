#!/usr/bin/env sh
set -eu

fail() {
  printf 'skill doc digests: %s\n' "$*" >&2
  exit 1
}

manifest_has_skill() {
  awk -F '\t' -v skill="$1" '
    !/^#/ && $1 == skill { found = 1 }
    END { exit found ? 0 : 1 }
  ' manifest.tsv
}

skill_digest() {
  digest_skill="$1"
  find "skills/$digest_skill" -type f | LC_ALL=C sort | while IFS= read -r digest_file; do
    printf '%s\n' "${digest_file#skills/$digest_skill/}"
    git hash-object "$digest_file"
  done | git hash-object --stdin
}

update_guide() {
  guide="$1"
  marker="$2"
  temporary=$(mktemp)

  if grep -E '^<!-- jig:skill-source-digest [0-9a-f]+ -->$' "$guide" >/dev/null 2>&1; then
    awk -v marker="$marker" '
      /^<!-- jig:skill-source-digest [0-9a-f]+ -->$/ { print marker; normalize_gap = 1; next }
      normalize_gap {
        if ($0 != "") print ""
        normalize_gap = 0
      }
      { print }
    ' "$guide" > "$temporary"
  else
    awk -v marker="$marker" '
      NR == 1 { print; print ""; print marker; print ""; next }
      NR == 2 && $0 == "" { next }
      { print }
    ' "$guide" > "$temporary"
  fi

  mv "$temporary" "$guide"
}

[ -f manifest.tsv ] || fail "run from the jig repository root"

if [ "$#" -eq 0 ]; then
  SKILLS=$(awk -F '\t' '!/^#/ && NF >= 1 { printf "%s ", $1 }' manifest.tsv)
else
  SKILLS="$*"
fi

for skill in $SKILLS; do
  manifest_has_skill "$skill" || fail "unknown manifest skill: $skill"
  [ -d "skills/$skill" ] || fail "missing skill source: skills/$skill"
  english="docs/en/skills/$skill.md"
  korean="docs/ko/skills/$skill.md"
  [ -f "$english" ] || fail "missing English guide: $english"
  [ -f "$korean" ] || fail "missing Korean guide: $korean"

  digest=$(skill_digest "$skill")
  marker="<!-- jig:skill-source-digest $digest -->"
  update_guide "$english" "$marker"
  update_guide "$korean" "$marker"
  printf 'skill doc digests: updated %s\n' "$skill"
done
