#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_dir="$repo_root/skill/spec-to-ship"

echo "Checking shell syntax..."
bash -n "$skill_dir"/scripts/*.sh
bash -n "$repo_root"/scripts/*.sh

echo "Checking skill frontmatter..."
grep -q '^name: spec-to-ship$' "$skill_dir/SKILL.md"
grep -q '^description:' "$skill_dir/SKILL.md"

echo "Checking policy pack index..."
bash "$skill_dir/scripts/spec-to-ship-policy-lint.sh"

echo "Running fallback workflow smoke test..."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
change="$tmp/spec-to-ship/changes/sample-change"
"$skill_dir/scripts/spec-to-ship-state.sh" init "$change" normal >/dev/null
if [ -e "$change/prototype.md" ]; then
  echo "ERROR: normal mode should not create prototype.md by default" >&2
  exit 1
fi

prototype_change="$tmp/spec-to-ship/changes/prototype-change"
"$skill_dir/scripts/spec-to-ship-state.sh" init "$prototype_change" prototype >/dev/null
if [ ! -s "$prototype_change/prototype.md" ]; then
  echo "ERROR: prototype mode should create prototype.md" >&2
  exit 1
fi

if "$skill_dir/scripts/spec-to-ship-state.sh" set "$change" phase build >/tmp/spec-to-ship-direct-phase.out 2>&1; then
  echo "ERROR: direct phase mutation should be blocked" >&2
  exit 1
fi

"$skill_dir/scripts/spec-to-ship-guard.sh" "$change" open --apply >/dev/null
"$skill_dir/scripts/spec-to-ship-checkpoint.sh" "$change" design "design confirmed" >/dev/null
"$skill_dir/scripts/spec-to-ship-context.sh" write "$change" build >/dev/null
perl -0pi -e 's/- \[ \] <task>/- [x] Sample task/' "$change/tasks.md"
printf '\nCommand: true\nResult: pass\nAcceptance scenario: pass\nResidual Risk: none\n' >> "$change/verify.md"
"$skill_dir/scripts/spec-to-ship-guard.sh" "$change" design --apply >/dev/null
"$skill_dir/scripts/spec-to-ship-guard.sh" "$change" build --apply >/dev/null
"$skill_dir/scripts/spec-to-ship-guard.sh" "$change" verify --apply >/dev/null
printf '\nRisk Level: Low\nCI or Local Substitute: true pass\nMigration Impact: N/A\nFeature Flag or Rollout Plan: N/A\nRollback Plan: revert commit\nMonitoring and Logging: N/A\nSecurity and Privacy Impact: N/A\n' >> "$change/release.md"
"$skill_dir/scripts/verify-production-ready.sh" "$change" >/dev/null
"$skill_dir/scripts/spec-to-ship-guard.sh" "$change" release-ready --apply >/dev/null
"$skill_dir/scripts/archive-change.sh" "$change" >/dev/null

if command -v openspec >/dev/null 2>&1; then
  echo "Validating optional OpenSpec schema..."
  schema_tmp="$(mktemp -d)"
  (
    cd "$schema_tmp"
    openspec init --tools none >/dev/null 2>&1
    "$skill_dir/scripts/install-openspec-schema.sh" "$schema_tmp" >/dev/null
    openspec schema validate spec-to-ship >/dev/null
  )
  rm -rf "$schema_tmp"
else
  echo "Skipping OpenSpec schema validation: openspec not found"
fi

echo "Validation passed."
