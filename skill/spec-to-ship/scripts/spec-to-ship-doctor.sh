#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
echo "Spec to Ship doctor for: $root"

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    echo "OK: $name ($(command -v "$name"))"
  else
    echo "MISSING: $name"
  fi
}

check_cmd git
check_cmd openspec
check_cmd codegraph

if [ -d "$root/.codegraph" ]; then
  echo "OK: .codegraph index exists"
else
  echo "INFO: .codegraph index not found; optional semantic indexing is not enabled"
fi

if [ -d "$root/openspec" ]; then
  echo "OK: openspec directory exists"
else
  echo "INFO: openspec directory not found; fallback spec-to-ship artifacts can still be used"
fi

if [ -d "$root/spec-to-ship" ]; then
  echo "OK: spec-to-ship fallback directory exists"
else
  echo "INFO: spec-to-ship fallback directory not found yet"
fi
