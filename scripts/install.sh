#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/skill/spec-to-ship"
target_dir="${CODEX_HOME:-$HOME/.codex}/skills/spec-to-ship"

if [ ! -f "$source_dir/SKILL.md" ]; then
  echo "ERROR: skill source not found: $source_dir" >&2
  exit 1
fi

mkdir -p "$(dirname "$target_dir")"
rm -rf "$target_dir"
cp -R "$source_dir" "$target_dir"
chmod +x "$target_dir"/scripts/*.sh

echo "Installed Spec to Ship skill to $target_dir"
echo "Restart or reload Codex, then invoke: \$spec-to-ship"
