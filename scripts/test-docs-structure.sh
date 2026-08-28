#!/usr/bin/env sh
set -eu

fail() {
  echo "docs structure tests: $*" >&2
  exit 1
}

english_docs=$(cd docs/en && find . -type f -name '*.md' | LC_ALL=C sort)
korean_docs=$(cd docs/ko && find . -type f -name '*.md' | LC_ALL=C sort)
[ "$english_docs" = "$korean_docs" ] || fail "docs/en and docs/ko paths differ"

if find docs -maxdepth 1 -type f -name '*.md' | grep -q .; then
  fail "Markdown files must be inside docs/en or docs/ko"
fi

if find docs -type f -name '*.ko.md' | grep -q .; then
  fail "localized docs must use docs/ko, not .ko.md suffixes"
fi

has_supported_mermaid() {
  awk '
    /^```mermaid$/ {
      if (getline > 0 && ($1 == "flowchart" || $1 == "sequenceDiagram" || $1 == "stateDiagram-v2")) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$1"
}

mermaid_type() {
  awk '/^```mermaid$/ { if (getline > 0) { print $1; exit } }' "$1"
}

for skill in $(awk -F '\t' '!/^#/ && NF >= 1 { print $1 }' manifest.tsv); do
  english="docs/en/skills/$skill.md"
  korean="docs/ko/skills/$skill.md"
  [ -f "$english" ] || fail "missing English skill guide: $skill"
  [ -f "$korean" ] || fail "missing Korean skill guide: $skill"
  grep -F "../../../skills/$skill/SKILL.md" "$english" >/dev/null || fail "English guide does not link its source: $skill"
  grep -F "../../../skills/$skill/SKILL.md" "$korean" >/dev/null || fail "Korean guide does not link its source: $skill"
  grep -F "../../ko/skills/$skill.md" "$english" >/dev/null || fail "English guide lacks Korean link: $skill"
  grep -F "../../en/skills/$skill.md" "$korean" >/dev/null || fail "Korean guide lacks English link: $skill"
  grep -F "($skill.md)" docs/en/skills/index.md >/dev/null || fail "English index does not link: $skill"
  grep -F "($skill.md)" docs/ko/skills/index.md >/dev/null || fail "Korean index does not link: $skill"
  has_supported_mermaid "$english" || fail "English guide lacks supported Mermaid: $skill"
  has_supported_mermaid "$korean" || fail "Korean guide lacks supported Mermaid: $skill"
  [ "$(mermaid_type "$english")" = "$(mermaid_type "$korean")" ] || fail "Mermaid type differs between languages: $skill"
done

has_supported_mermaid docs/en/skills/index.md || fail "English skill index lacks supported Mermaid"
has_supported_mermaid docs/ko/skills/index.md || fail "Korean skill index lacks supported Mermaid"
[ "$(mermaid_type docs/en/skills/index.md)" = "$(mermaid_type docs/ko/skills/index.md)" ] || fail "skill index Mermaid types differ"

for file in README.md README.ko.md $(find docs -type f -name '*.md' | LC_ALL=C sort); do
  links=$(grep -oE '\]\([^)]+\)' "$file" 2>/dev/null || true)
  [ -n "$links" ] || continue
  printf '%s\n' "$links" | sed 's/^](//; s/)$//' | while IFS= read -r link; do
    case "$link" in
      ''|'#'*|http://*|https://*|mailto:*) continue ;;
    esac
    target=${link%%#*}
    [ -e "$(dirname "$file")/$target" ] || fail "broken relative link in $file: $link"
  done
done

echo "docs structure tests ok"
