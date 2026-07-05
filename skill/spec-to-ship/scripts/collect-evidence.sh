#!/usr/bin/env bash
set -euo pipefail

dir="${1:-}"
if [ -z "$dir" ]; then
  echo "Usage: collect-evidence.sh <change-dir>" >&2
  exit 2
fi

mkdir -p "$dir"
verify="$dir/verify.md"
now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

{
  echo
  echo "## Evidence Snapshot - $now"
  echo
  echo "### Git Branch"
  git branch --show-current 2>/dev/null || echo "N/A"
  echo
  echo "### Git Status"
  git status --short 2>/dev/null || echo "N/A"
  echo
  echo "### Changed Files"
  git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "N/A"
} >> "$verify"

echo "Evidence appended to $verify"
