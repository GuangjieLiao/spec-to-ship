#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: spec-to-ship-guard.sh <change-dir> <stage> [--apply]" >&2
}

dir="${1:-}"
stage="${2:-}"
apply="${3:-}"

if [ -z "$dir" ] || [ -z "$stage" ]; then
  usage
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_script="$script_dir/spec-to-ship-state.sh"
state="$dir/.spec-to-ship.yaml"

failures=()

fail() {
  failures+=("$1")
}

require_file() {
  local file="$1"
  if [ ! -s "$dir/$file" ]; then
    fail "$file is missing or empty"
  fi
}

require_text() {
  local file="$1"
  local pattern="$2"
  if [ -f "$dir/$file" ] && ! grep -Eq "$pattern" "$dir/$file"; then
    fail "$file does not contain required marker: $pattern"
  fi
}

mode="normal"
if [ -f "$state" ]; then
  mode="$(awk -F': *' '$1=="mode"{print $2; exit}' "$state")"
else
  fail ".spec-to-ship.yaml is missing"
fi

case "$stage" in
  open)
    require_file proposal.md
    require_file spec.md
    require_text proposal.md "Problem|问题"
    require_text proposal.md "Goal|目标"
    require_text proposal.md "Non-goals|非目标"
    require_text proposal.md "Acceptance|验收|Scenario|场景"
    ;;
  design)
    if [ "$mode" != "tweak" ]; then
      require_file design.md
      require_text design.md "Chosen Approach|技术方案|方案"
      require_text design.md "Test Strategy|测试策略"
    fi
    ;;
  build)
    require_file tasks.md
    if grep -Eq '^- \[ \]' "$dir/tasks.md"; then
      fail "tasks.md still has unchecked tasks"
    fi
    require_text tasks.md "Evidence|证据"
    ;;
  verify)
    require_file verify.md
    require_text verify.md "Commands Run|命令|Commands"
    require_text verify.md "Acceptance|验收|Scenario|场景"
    require_text verify.md "Residual Risk|风险"
    if grep -Eiq 'critical.*fail|fail.*critical|build failed|test failed' "$dir/verify.md"; then
      fail "verify.md contains critical failure wording"
    fi
    ;;
  release-ready)
    if [ "$mode" != "tweak" ]; then
      require_file release.md
      require_text release.md "Rollback|回滚"
      require_text release.md "Monitoring|监控|Logging|日志"
      require_text release.md "Security|安全|Privacy|隐私"
    fi
    ;;
  archive)
    require_file verify.md
    if [ "$mode" != "tweak" ]; then
      require_file release.md
    fi
    ;;
  *)
    fail "unknown stage: $stage"
    ;;
esac

if [ "${#failures[@]}" -gt 0 ]; then
  echo "FAIL: $stage guard failed for $dir"
  for item in "${failures[@]}"; do
    echo "- $item"
  done
  exit 1
fi

echo "PASS: $stage guard passed for $dir"

if [ "$apply" = "--apply" ]; then
  case "$stage" in
    open) event="open-complete" ;;
    design) event="design-complete" ;;
    build) event="build-complete" ;;
    verify) event="verify-pass" ;;
    release-ready) event="release-pass" ;;
    archive)
      event="archive-complete"
      ;;
  esac
  "$state_script" transition "$dir" "$event" >/dev/null
  "$state_script" next "$dir"
fi
