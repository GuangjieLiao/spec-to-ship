#!/usr/bin/env bash
set -euo pipefail

dir="${1:-}"
if [ -z "$dir" ]; then
  echo "Usage: verify-production-ready.sh <change-dir>" >&2
  exit 2
fi

release="$dir/release.md"
if [ ! -f "$release" ]; then
  echo "FAIL: release.md missing"
  exit 1
fi

missing=0
check() {
  local label="$1"
  local pattern="$2"
  if grep -Eiq "$pattern" "$release"; then
    echo "OK: $label"
  else
    echo "MISSING: $label"
    missing=1
  fi
}

check "risk level" "Risk Level|风险等级"
check "CI or local substitute" "CI|Local Substitute|本地替代|构建|测试"
check "migration impact" "Migration|迁移|数据库|N/A"
check "rollout or feature flag" "Feature Flag|Rollout|灰度|发布|N/A"
check "rollback plan" "Rollback|回滚"
check "monitoring/logging" "Monitoring|Logging|监控|日志|N/A"
check "security/privacy impact" "Security|Privacy|安全|隐私|N/A"

if [ "$missing" -ne 0 ]; then
  echo "FAIL: production readiness is incomplete"
  exit 1
fi

echo "PASS: production readiness checklist is present"
