#!/usr/bin/env bash
set -euo pipefail

dir="${1:-}"
stage="${2:-}"
note="${3:-checkpoint}"

if [ -z "$dir" ] || [ -z "$stage" ]; then
  echo "Usage: spec-to-ship-checkpoint.sh <change-dir> <stage> [note]" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_script="$script_dir/spec-to-ship-state.sh"
mkdir -p "$dir/.spec-to-ship/checkpoints"
file="$dir/.spec-to-ship/checkpoints/${stage}.md"
now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

{
  echo
  echo "## $now"
  echo
  echo "$note"
} >> "$file"

case "$stage" in
  design|build|verify)
    "$state_script" set "$dir" "${stage}_checkpoint" "$file" >/dev/null
    ;;
esac

echo "Checkpoint appended: $file"
