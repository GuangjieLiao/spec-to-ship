#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
src="$skill_dir/assets/openspec-schema/spec-to-ship"
target="$root/openspec/schemas/spec-to-ship"

if [ ! -f "$src/schema.yaml" ]; then
  echo "ERROR: schema asset missing: $src" >&2
  exit 1
fi

rm -rf "$target"
mkdir -p "$(dirname "$target")"
cp -R "$src" "$target"
echo "Installed OpenSpec schema to $target"
