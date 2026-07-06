#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
index="$skill_dir/references/policy-packs.md"
policy_dir="$skill_dir/assets/policy-packs"
skill_file="$skill_dir/SKILL.md"

if [ ! -f "$index" ]; then
  echo "ERROR: policy pack index missing: $index" >&2
  exit 1
fi

if [ ! -d "$policy_dir" ]; then
  echo "ERROR: policy pack directory missing: $policy_dir" >&2
  exit 1
fi

if ! grep -Fq "references/policy-packs.md" "$skill_file"; then
  echo "ERROR: SKILL.md must reference references/policy-packs.md" >&2
  exit 1
fi

missing=0
found=0

for file in "$policy_dir"/*.md; do
  [ -e "$file" ] || continue
  found=1
  base="$(basename "$file")"
  if ! grep -Fq "$base" "$index"; then
    echo "ERROR: policy pack is not indexed in references/policy-packs.md: $base" >&2
    missing=1
  fi
done

if [ "$found" -eq 0 ]; then
  echo "ERROR: no policy packs found in $policy_dir" >&2
  exit 1
fi

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "Policy pack index is valid."
