#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  spec-to-ship-context.sh write <change-dir> <stage> [--full]
  spec-to-ship-context.sh hash <change-dir>
EOF
}

cmd="${1:-}"
dir="${2:-}"
stage="${3:-context}"
mode="${4:-}"

if [ -z "$cmd" ] || [ -z "$dir" ]; then
  usage
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_script="$script_dir/spec-to-ship-state.sh"

hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    cksum "$1" | awk '{print $1}'
  fi
}

artifact_files() {
  for file in proposal.md spec.md design.md tasks.md verify.md release.md; do
    [ -f "$dir/$file" ] && printf '%s\n' "$dir/$file"
  done
  if [ -d "$dir/specs" ]; then
    find "$dir/specs" -type f -name '*.md' | sort
  fi
}

combined_hash() {
  tmp="$(mktemp)"
  artifact_files | while IFS= read -r file; do
    printf '%s  %s\n' "$(hash_file "$file")" "$file"
  done > "$tmp"
  hash_file "$tmp"
  rm -f "$tmp"
}

case "$cmd" in
  hash)
    combined_hash
    ;;
  write)
    mkdir -p "$dir/.spec-to-ship/handoff"
    hash="$(combined_hash)"
    out_md="$dir/.spec-to-ship/handoff/${stage}-context.md"
    out_json="$dir/.spec-to-ship/handoff/${stage}-context.json"
    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    {
      echo "# Spec to Ship Context Pack"
      echo
      echo "- Change: $(basename "$dir")"
      echo "- Stage: $stage"
      echo "- Generated: $now"
      echo "- Hash: $hash"
      echo "- Mode: ${mode#--}"
      echo
      for file in $(artifact_files); do
        rel="${file#$dir/}"
        echo "## $rel"
        echo
        echo "- sha256: $(hash_file "$file")"
        echo
        if [ "$mode" = "--full" ]; then
          sed -n '1,400p' "$file"
        else
          sed -n '1,160p' "$file"
          lines="$(wc -l < "$file" | tr -d ' ')"
          if [ "${lines:-0}" -gt 160 ]; then
            echo
            echo "[TRUNCATED: read $rel directly if full context is needed]"
          fi
        fi
        echo
      done
    } > "$out_md"
    {
      echo "{"
      echo "  \"change\": \"$(basename "$dir")\","
      echo "  \"stage\": \"$stage\","
      echo "  \"generated_at\": \"$now\","
      echo "  \"hash\": \"$hash\","
      echo "  \"context_md\": \"$out_md\","
      echo "  \"files\": ["
      first=1
      artifact_files | while IFS= read -r file; do
        rel="${file#$dir/}"
        h="$(hash_file "$file")"
        if [ "$first" -eq 0 ]; then echo ","; fi
        first=0
        printf '    {"path": "%s", "sha256": "%s"}' "$rel" "$h"
      done
      echo
      echo "  ]"
      echo "}"
    } > "$out_json"
    "$state_script" set "$dir" context_pack "$out_json" >/dev/null
    "$state_script" set "$dir" context_hash "$hash" >/dev/null
    echo "Wrote context pack: $out_md"
    ;;
  *)
    usage
    exit 2
    ;;
esac
