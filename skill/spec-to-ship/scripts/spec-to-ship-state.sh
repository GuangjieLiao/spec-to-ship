#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  spec-to-ship-state.sh init <change-dir> <mode>
  spec-to-ship-state.sh get <change-dir> [field]
  spec-to-ship-state.sh set <change-dir> <field> <value>
  spec-to-ship-state.sh transition <change-dir> <event>
  spec-to-ship-state.sh next <change-dir>
  spec-to-ship-state.sh archive <change-dir>
EOF
}

cmd="${1:-}"
if [ -z "$cmd" ]; then
  usage
  exit 2
fi
shift || true

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"

state_file() {
  printf '%s/.spec-to-ship.yaml\n' "$1"
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

ensure_state() {
  local dir="$1"
  local state
  state="$(state_file "$dir")"
  if [ ! -f "$state" ]; then
    echo "ERROR: state file not found: $state" >&2
    exit 1
  fi
}

set_field() {
  local dir="$1"
  local key="$2"
  local value="$3"
  ensure_state "$dir"
  local state tmp
  state="$(state_file "$dir")"
  tmp="${state}.tmp.$$"
  awk -v k="$key" -v v="$value" '
    BEGIN { done=0 }
    $0 ~ "^" k ":" {
      print k ": " v
      done=1
      next
    }
    { print }
    END {
      if (!done) print k ": " v
    }
  ' "$state" > "$tmp"
  mv "$tmp" "$state"
  if [ "$key" != "updated_at" ]; then
    set_field "$dir" "updated_at" "$(timestamp)"
  fi
}

get_field() {
  local dir="$1"
  local key="$2"
  ensure_state "$dir"
  awk -F': *' -v k="$key" '$1 == k { print substr($0, index($0,$2)); found=1 } END { exit found ? 0 : 1 }' "$(state_file "$dir")"
}

require_file() {
  local dir="$1"
  local file="$2"
  if [ ! -s "$dir/$file" ]; then
    echo "ERROR: required artifact missing or empty: $dir/$file" >&2
    exit 1
  fi
}

transition() {
  local dir="$1"
  local event="$2"
  local mode phase next
  ensure_state "$dir"
  mode="$(get_field "$dir" mode 2>/dev/null || echo normal)"
  phase="$(get_field "$dir" phase 2>/dev/null || echo open)"
  case "$event" in
    open-complete)
      [ "$phase" = "open" ] || { echo "ERROR: open-complete requires phase=open, got $phase" >&2; exit 1; }
      require_file "$dir" proposal.md
      require_file "$dir" spec.md
      if [ "$mode" = "tweak" ] || [ "$mode" = "hotfix" ]; then next="build"; else next="design"; fi
      ;;
    design-complete)
      [ "$phase" = "design" ] || { echo "ERROR: design-complete requires phase=design, got $phase" >&2; exit 1; }
      require_file "$dir" design.md
      next="build"
      ;;
    build-complete)
      [ "$phase" = "build" ] || { echo "ERROR: build-complete requires phase=build, got $phase" >&2; exit 1; }
      require_file "$dir" tasks.md
      next="verify"
      ;;
    verify-pass)
      [ "$phase" = "verify" ] || { echo "ERROR: verify-pass requires phase=verify, got $phase" >&2; exit 1; }
      require_file "$dir" verify.md
      set_field "$dir" verification_result pass
      if [ "$mode" = "tweak" ]; then next="archive"; else next="release-ready"; fi
      ;;
    verify-fail)
      set_field "$dir" verification_result fail
      current_count="$(get_field "$dir" verify_fail_count 2>/dev/null || echo 0)"
      case "$current_count" in ''|*[!0-9]*) current_count=0 ;; esac
      set_field "$dir" verify_fail_count "$((current_count + 1))"
      next="build"
      ;;
    release-pass)
      [ "$phase" = "release-ready" ] || { echo "ERROR: release-pass requires phase=release-ready, got $phase" >&2; exit 1; }
      require_file "$dir" release.md
      set_field "$dir" release_result pass
      next="archive"
      ;;
    archive-complete)
      [ "$phase" = "archive" ] || { echo "ERROR: archive-complete requires phase=archive, got $phase" >&2; exit 1; }
      set_field "$dir" archived true
      next="archived"
      ;;
    *)
      echo "ERROR: unknown transition event: $event" >&2
      exit 2
      ;;
  esac
  set_field "$dir" phase "$next"
  echo "Transitioned $event -> phase=$next"
}

copy_template() {
  local name="$1"
  local target="$2"
  if [ ! -f "$target" ]; then
    cp "$skill_dir/assets/${name}-template.md" "$target"
  fi
}

case "$cmd" in
  init)
    dir="${1:-}"
    mode="${2:-normal}"
    if [ -z "$dir" ]; then
      usage
      exit 2
    fi
    mkdir -p "$dir"
    change_name="$(basename "$dir")"
    state="$(state_file "$dir")"
    if [ ! -f "$state" ]; then
      now="$(timestamp)"
      cat > "$state" <<EOF
change: $change_name
mode: $mode
phase: open
archived: false
created_at: $now
updated_at: $now
review_mode: null
tdd_mode: null
prototype_source: null
prototype_fidelity: not_applicable
auto_transition: true
context_compression: pack
context_pack: null
context_hash: null
design_checkpoint: null
build_checkpoint: null
verify_checkpoint: null
verify_fail_count: 0
schema: fallback
code_index: optional
verification_result: pending
release_result: pending
EOF
    fi
    copy_template proposal "$dir/proposal.md"
    copy_template spec "$dir/spec.md"
    copy_template design "$dir/design.md"
    copy_template tasks "$dir/tasks.md"
    copy_template verify "$dir/verify.md"
    copy_template release "$dir/release.md"
    copy_template prototype "$dir/prototype.md"
    echo "Initialized $dir"
    ;;
  get)
    dir="${1:-}"
    field="${2:-}"
    if [ -z "$dir" ]; then
      usage
      exit 2
    fi
    ensure_state "$dir"
    state="$(state_file "$dir")"
    if [ -z "$field" ]; then
      cat "$state"
    else
      awk -F': *' -v k="$field" '$1 == k { print substr($0, index($0,$2)); found=1 } END { exit found ? 0 : 1 }' "$state"
    fi
    ;;
  set)
    dir="${1:-}"
    field="${2:-}"
    value="${3:-}"
    if [ -z "$dir" ] || [ -z "$field" ]; then
      usage
      exit 2
    fi
    if [ "$field" = "phase" ] && [ "${SPEC_TO_SHIP_FORCE_PHASE:-}" != "1" ]; then
      echo "ERROR: direct phase mutation is blocked. Use transition or guard --apply. Set SPEC_TO_SHIP_FORCE_PHASE=1 only for repair." >&2
      exit 1
    fi
    set_field "$dir" "$field" "$value"
    echo "Set $field=$value in $dir"
    ;;
  transition)
    dir="${1:-}"
    event="${2:-}"
    if [ -z "$dir" ] || [ -z "$event" ]; then
      usage
      exit 2
    fi
    transition "$dir" "$event"
    ;;
  next)
    dir="${1:-}"
    if [ -z "$dir" ]; then
      usage
      exit 2
    fi
    ensure_state "$dir"
    phase="$(get_field "$dir" phase 2>/dev/null || echo open)"
    auto="$(get_field "$dir" auto_transition 2>/dev/null || echo true)"
    case "$phase" in
      open) skill="spec-to-ship open" ;;
      design) skill="spec-to-ship design" ;;
      build) skill="spec-to-ship build" ;;
      verify) skill="spec-to-ship verify" ;;
      release-ready) skill="spec-to-ship release-ready" ;;
      archive) skill="spec-to-ship archive" ;;
      archived) echo "NEXT: done"; exit 0 ;;
      *) skill="spec-to-ship $phase" ;;
    esac
    if [ "$auto" = "false" ]; then
      echo "NEXT: manual"
      echo "SKILL: $skill"
      echo "HINT: auto_transition=false, wait for user before continuing."
    else
      echo "NEXT: auto"
      echo "SKILL: $skill"
    fi
    ;;
  archive)
    dir="${1:-}"
    if [ -z "$dir" ]; then
      usage
      exit 2
    fi
    ensure_state "$dir"
    set_field "$dir" archived true
    SPEC_TO_SHIP_FORCE_PHASE=1 set_field "$dir" phase archived
    echo "Archived state updated for $dir"
    ;;
  *)
    usage
    exit 2
    ;;
esac
