#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  spec-to-ship-init.sh [target-dir] [--force]

Initializes project-level agent docs from bundled templates.
By default, existing files are preserved.
EOF
}

target="."
force="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      target="$1"
      shift
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
template_dir="$skill_dir/assets/project-docs"

if [ ! -d "$template_dir" ]; then
  echo "ERROR: project-doc templates missing: $template_dir" >&2
  exit 1
fi

mkdir -p "$target"
target="$(cd "$target" && pwd)"
project_name="$(basename "$target")"
generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

created=0
skipped=0

while IFS= read -r src; do
  rel="${src#$template_dir/}"
  dest="$target/$rel"
  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] && [ "$force" != "true" ]; then
    echo "SKIP existing $rel"
    skipped=$((skipped + 1))
    continue
  fi

  sed \
    -e "s/{{PROJECT_NAME}}/$project_name/g" \
    -e "s/{{GENERATED_AT}}/$generated_at/g" \
    "$src" > "$dest"
  echo "CREATE $rel"
  created=$((created + 1))
done < <(find "$template_dir" -type f | sort)

echo "Initialized agent docs in $target"
echo "Created: $created"
echo "Skipped: $skipped"
