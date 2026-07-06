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
grep -q 'Default all prose in generated artifacts to Chinese' "$skill_dir/SKILL.md"
grep -q '^# 变更提案$' "$skill_dir/assets/proposal-template.md"
grep -q '^# 技术设计$' "$skill_dir/assets/design-template.md"
grep -q '^# 任务$' "$skill_dir/assets/tasks-template.md"
grep -q '^# 验证$' "$skill_dir/assets/verify-template.md"
grep -q '^# 发布准备$' "$skill_dir/assets/release-template.md"

echo "Checking policy pack index..."
bash "$skill_dir/scripts/spec-to-ship-policy-lint.sh"

echo "Running init workflow smoke test..."
init_tmp="$(mktemp -d)"
mkdir -p "$init_tmp/src" "$init_tmp/tests" "$init_tmp/.github/workflows"
cat > "$init_tmp/package.json" <<'JSON'
{"scripts":{"dev":"vite","build":"vite build","test":"vitest","lint":"eslint ."}}
JSON
touch "$init_tmp/pnpm-lock.yaml" "$init_tmp/.github/workflows/ci.yml"
bash "$skill_dir/scripts/spec-to-ship-init.sh" "$init_tmp" >/dev/null
for expected in \
  AGENTS.md \
  docs/agent-map.md \
  docs/architecture-index.md \
  docs/domain-map.md \
  docs/decisions/0001-initialize-agent-docs.md \
  docs/tech-debt.md \
  docs/quality-score.md \
  spec-to-ship/config.yaml
do
  if [ ! -s "$init_tmp/$expected" ]; then
    echo "ERROR: init did not create expected file: $expected" >&2
    exit 1
  fi
done
grep -q 'pnpm run dev' "$init_tmp/AGENTS.md"
grep -q 'pnpm test' "$init_tmp/docs/agent-map.md"
grep -q 'src/' "$init_tmp/docs/agent-map.md"
grep -q '.github/workflows' "$init_tmp/docs/agent-map.md"
grep -q '## 项目概览' "$init_tmp/AGENTS.md"
grep -q 'language: zh-CN' "$init_tmp/spec-to-ship/config.yaml"
en_tmp="$(mktemp -d)"
cp "$init_tmp/package.json" "$en_tmp/package.json"
cp "$init_tmp/pnpm-lock.yaml" "$en_tmp/pnpm-lock.yaml"
mkdir -p "$en_tmp/src" "$en_tmp/tests"
bash "$skill_dir/scripts/spec-to-ship-init.sh" "$en_tmp" --lang en >/dev/null
grep -q '## Project Summary' "$en_tmp/AGENTS.md"
grep -q 'pnpm run dev' "$en_tmp/AGENTS.md"
grep -q 'language: en' "$en_tmp/spec-to-ship/config.yaml"
rm -rf "$en_tmp"

maven_tmp="$(mktemp -d)"
cat > "$maven_tmp/README.md" <<'EOF'
# Sample Maven Project

## Code Structure
- sample-api interface contracts
- sample-job scheduled jobs
- sample-provider main business service

## Architecture
- Framework: Spring Boot
- Persistence: MyBatisPlus
- Config center: Apollo
- Database: MySQL
- Cache: Redis
- MQ: ActiveMQ

## Development Rules
- Public APIs must use /sample/open-api prefix.
EOF
cat > "$maven_tmp/pom.xml" <<'XML'
<project>
  <modules>
    <module>sample-api</module>
    <module>sample-job</module>
    <module>sample-provider</module>
    <module>sample-dependency</module>
  </modules>
</project>
XML
mkdir -p "$maven_tmp/sample-api/src/main" "$maven_tmp/sample-api/target"
mkdir -p "$maven_tmp/sample-job/src/main" "$maven_tmp/sample-job/src/test"
mkdir -p "$maven_tmp/sample-provider/src/main/java/com/acme/sample" "$maven_tmp/sample-provider/src/main/resources"
mkdir -p "$maven_tmp/sample-provider/src/main/java/com/acme/sample/controller/invoice" "$maven_tmp/sample-provider/src/main/java/com/acme/sample/controller/rebate"
mkdir -p "$maven_tmp/sample-dependency/lib-sample-repo"
touch "$maven_tmp/sample-api/pom.xml" "$maven_tmp/sample-job/pom.xml" "$maven_tmp/sample-provider/pom.xml" "$maven_tmp/sample-dependency/pom.xml"
touch "$maven_tmp/sample-dependency/lib-sample-repo/local.jar"
cat > "$maven_tmp/sample-provider/src/main/java/com/acme/sample/SampleApplication.java" <<'JAVA'
package com.acme.sample;

@SpringBootApplication
public class SampleApplication {}
JAVA
cat > "$maven_tmp/sample-provider/src/main/java/com/acme/sample/controller/invoice/InvoiceController.java" <<'JAVA'
package com.acme.sample.controller.invoice;

@RestController
public class InvoiceController {}
JAVA
cat > "$maven_tmp/sample-provider/src/main/java/com/acme/sample/controller/rebate/RebateController.java" <<'JAVA'
package com.acme.sample.controller.rebate;

@RestController
public class RebateController {}
JAVA
touch "$maven_tmp/sample-provider/src/main/resources/application.yml" "$maven_tmp/sample-provider/src/main/resources/application-dev.yml"
bash "$skill_dir/scripts/spec-to-ship-init.sh" "$maven_tmp" >/dev/null
grep -q 'sample-api' "$maven_tmp/docs/agent-map.md"
grep -q 'sample-job/src/test' "$maven_tmp/docs/agent-map.md"
grep -q 'local.jar' "$maven_tmp/docs/agent-map.md"
grep -q 'sample-api/target' "$maven_tmp/docs/quality-score.md"
grep -q 'README 标题' "$maven_tmp/AGENTS.md"
grep -q 'Spring Boot' "$maven_tmp/docs/architecture-index.md"
grep -q 'MySQL' "$maven_tmp/docs/agent-map.md"
grep -q 'Redis' "$maven_tmp/docs/agent-map.md"
grep -q 'ActiveMQ' "$maven_tmp/docs/agent-map.md"
grep -q 'Apollo' "$maven_tmp/docs/agent-map.md"
grep -q 'sample-job.*scheduled jobs' "$maven_tmp/docs/agent-map.md"
grep -q 'SampleApplication.java' "$maven_tmp/docs/agent-map.md"
grep -q 'application-dev.yml' "$maven_tmp/docs/agent-map.md"
grep -q 'sample-provider/src/main/resources.*application-dev.yml' "$maven_tmp/docs/agent-map.md"
if grep -q 'sample-provider/src/main/resources/application-dev.yml' "$maven_tmp/docs/agent-map.md"; then
  echo "ERROR: runtime configs should be grouped, not listed as one line per file" >&2
  exit 1
fi
grep -q 'controller/invoice' "$maven_tmp/docs/domain-map.md"
grep -q 'controller/rebate' "$maven_tmp/docs/domain-map.md"
grep -q 'domain_map: docs/domain-map.md' "$maven_tmp/spec-to-ship/config.yaml"
grep -q '运行命令/profile 待确认' "$maven_tmp/docs/tech-debt.md"
if grep -q '确认项目类型、命令、测试和架构' "$maven_tmp/docs/tech-debt.md"; then
  echo "ERROR: tech debt investigation item should not stay generic after project facts were detected" >&2
  exit 1
fi
grep -q '/sample/open-api' "$maven_tmp/AGENTS.md"
rm -rf "$maven_tmp"

printf 'custom\n' > "$init_tmp/AGENTS.md"
bash "$skill_dir/scripts/spec-to-ship-init.sh" "$init_tmp" >/dev/null
if [ "$(cat "$init_tmp/AGENTS.md")" != "custom" ]; then
  echo "ERROR: init should preserve existing files by default" >&2
  exit 1
fi
rm -rf "$init_tmp"

echo "Running fallback workflow smoke test..."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
change="$tmp/spec-to-ship/changes/sample-change"
"$skill_dir/scripts/spec-to-ship-state.sh" init "$change" normal >/dev/null
grep -q '^# 变更提案$' "$change/proposal.md"
grep -q '^# 技术设计$' "$change/design.md"
grep -q '^# 任务$' "$change/tasks.md"
grep -q '^# 验证$' "$change/verify.md"
grep -q '^# 发布准备$' "$change/release.md"
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
grep -q '^# 原型$' "$prototype_change/prototype.md"

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
