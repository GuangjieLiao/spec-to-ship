#!/usr/bin/env bash
set -euo pipefail

dir="${1:-}"
if [ -z "$dir" ]; then
  echo "Usage: archive-change.sh <change-dir>" >&2
  exit 2
fi

if [ ! -d "$dir" ]; then
  echo "ERROR: change directory not found: $dir" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
guard="$script_dir/spec-to-ship-guard.sh"
state="$script_dir/spec-to-ship-state.sh"

"$guard" "$dir" archive >/dev/null
"$state" archive "$dir" >/dev/null

base="$(basename "$dir")"
parent="$(dirname "$dir")"
if [ "$(basename "$parent")" = "changes" ]; then
  archive_root="$(dirname "$parent")/archive"
else
  archive_root="$parent/archive"
fi

mkdir -p "$archive_root"
target="$archive_root/$(date +%F)-$base"
if [ -e "$target" ]; then
  echo "ERROR: archive target already exists: $target" >&2
  exit 1
fi

mv "$dir" "$target"
echo "Archived to $target"
