#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  spec-to-ship-init.sh [target-dir] [--force] [--lang zh-CN|en]

Initializes project-level agent docs from bundled templates.
By default, existing files are preserved.
Default language is zh-CN.
The initializer scans the target project and records only facts it can infer from files.
EOF
}

target="."
force="false"
lang="zh-CN"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="true"
      shift
      ;;
    --lang)
      lang="${2:-}"
      if [ -z "$lang" ]; then
        echo "ERROR: --lang requires a value: en or zh-CN" >&2
        exit 2
      fi
      shift 2
      ;;
    --lang=*)
      lang="${1#--lang=}"
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

case "$lang" in
  en)
    template_dir="$skill_dir/assets/project-docs"
    ;;
  zh-CN)
    template_dir="$skill_dir/assets/project-docs-zh-CN"
    ;;
  *)
    echo "ERROR: unsupported language: $lang. Use en or zh-CN." >&2
    exit 2
    ;;
esac

if [ ! -d "$template_dir" ]; then
  echo "ERROR: project-doc templates missing: $template_dir" >&2
  exit 1
fi

mkdir -p "$target"
target="$(cd "$target" && pwd)"
project_name="$(basename "$target")"
generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

has_file() {
  [ -f "$target/$1" ]
}

has_dir() {
  [ -d "$target/$1" ]
}

json_script_exists() {
  local script="$1"
  has_file package.json && grep -Eq "\"$script\"[[:space:]]*:" "$target/package.json"
}

append_line() {
  local var_name="$1"
  local line="$2"
  local current="${!var_name:-}"
  if [ -z "$current" ]; then
    printf -v "$var_name" '%s' "$line"
  else
    printf -v "$var_name" '%s\n%s' "$current" "$line"
  fi
}

append_unique_line() {
  local var_name="$1"
  local line="$2"
  local current="${!var_name:-}"
  if [ -n "$current" ] && printf '%s\n' "$current" | grep -Fxq -- "$line"; then
    return 0
  fi
  append_line "$var_name" "$line"
}

command_or_unknown() {
  local label="$1"
  local value="$2"
  if [ -n "$value" ]; then
    printf -- '- %s: `%s`\n' "$label" "$value"
  else
    printf -- '- %s: %s\n' "$label" "${not_established:-not established.}"
  fi
}

if [ "$lang" = "zh-CN" ]; then
  unknown_project="- 未识别或空项目。首次实现变更后请更新。"
  no_source="- 暂未确认源码结构。"
  no_tests="- 暂未确认测试结构。"
  no_ci="- 暂未确认 CI/CD 入口。"
  no_datastore="- 暂未确认数据存储。"
  no_external="- 暂未确认外部服务依赖。"
  no_paths="- 暂未检测到项目特定源码、测试或 CI 路径。"
  label_install="安装"
  label_run="运行"
  label_test="测试"
  label_build="构建"
  label_lint="Lint/typecheck"
  not_established="未建立。"
else
  unknown_project="- Unknown or blank project. Update after the first implementation change."
  no_source="- No source layout has been confirmed yet."
  no_tests="- No test layout has been confirmed yet."
  no_ci="- No CI/CD entry point has been confirmed yet."
  no_datastore="- No datastore has been confirmed yet."
  no_external="- No external service dependency has been confirmed yet."
  no_paths="- No project-specific source, test, or CI paths were detected yet."
  label_install="Install"
  label_run="Run"
  label_test="Test"
  label_build="Build"
  label_lint="Lint/typecheck"
  not_established="not established."
fi

project_type=""
source_layout=""
test_layout=""
ci_cd=""
data_stores=""
external_services=""
important_paths=""
readme_summary=""
readme_file=""
module_summary=""
build_outputs=""
local_dependencies=""
runtime_stack=""
runtime_configs=""
entrypoints=""
project_rules=""
known_unknowns=""
domain_map=""
domain_gaps=""
tech_debt_investigation=""

install_cmd=""
run_cmd=""
test_cmd=""
build_cmd=""
lint_cmd=""

extract_readme_summary() {
  if has_file README.md; then
    readme_file="$target/README.md"
  elif has_file README; then
    readme_file="$target/README"
  fi

  if [ -n "$readme_file" ]; then
    local title
    title="$(grep -m 1 -E '^#+' "$readme_file" 2>/dev/null | sed -E 's/^#+[[:space:]]*//;s/\*\*//g' || true)"
    if [ -n "$title" ]; then
      if [ "$lang" = "zh-CN" ]; then
        append_line readme_summary "- README 标题：$title"
      else
        append_line readme_summary "- README title: $title"
      fi
    else
      if [ "$lang" = "zh-CN" ]; then
        append_line readme_summary "- 检测到 README，但未找到一级标题。"
      else
        append_line readme_summary "- README detected, but no top-level title was found."
      fi
    fi
    append_line important_paths "- \`$(basename "$readme_file")\`"
  fi
}

append_readme_fact() {
  local var_name="$1"
  local label="$2"
  if [ "$lang" = "zh-CN" ]; then
    append_unique_line "$var_name" "- ${label}（来源：\`$(basename "$readme_file")\`）。"
  else
    append_unique_line "$var_name" "- $label (source: \`$(basename "$readme_file")\`)."
  fi
}

readme_has() {
  local pattern="$1"
  [ -n "$readme_file" ] && grep -Eiq "$pattern" "$readme_file"
}

scan_readme_facts() {
  [ -n "$readme_file" ] || return 0

  readme_has 'Spring[[:space:]]*Boot|Springboot' && append_readme_fact runtime_stack "Spring Boot"
  readme_has 'MyBatis[[:space:]]*Plus|MyBatisPlus' && append_readme_fact runtime_stack "MyBatisPlus"
  readme_has 'Spring[[:space:]]*Cloud[[:space:]]*Netflix' && append_readme_fact runtime_stack "Spring Cloud Netflix"
  readme_has 'Swagger' && append_readme_fact runtime_stack "Swagger"
  readme_has 'PowerJob' && append_readme_fact runtime_stack "PowerJob"
  readme_has 'EasyPoi|EasyPOI' && append_readme_fact runtime_stack "EasyPoi"
  readme_has 'EasyExcel' && append_readme_fact runtime_stack "EasyExcel"

  readme_has 'MySQL|Mysql' && append_readme_fact data_stores "MySQL"
  readme_has 'Redis' && append_readme_fact data_stores "Redis"

  readme_has 'Apollo' && append_readme_fact external_services "Apollo 配置中心"
  readme_has 'ActiveMQ|ActiveMq' && append_readme_fact external_services "ActiveMQ"
  readme_has 'SLS|sls|日志中心|阿里云' && append_readme_fact external_services "日志中心 / SLS"
  readme_has 'Nginx' && append_readme_fact external_services "Nginx"

  local rules
  rules="$(awk '
    /^##[[:space:]]*(三、)?开发规范/ || /^##[[:space:]]*Development Rules/ { in_rules=1; next }
    /^##[[:space:]]/ && in_rules { in_rules=0 }
    in_rules { print }
  ' "$readme_file" 2>/dev/null | grep -Eiv '^[[:space:]]*$|^---$' | sed -E 's/\r//;s/^[[:space:]>*-]+//;s/[[:space:]]+/ /g;s/[[:space:]]$//' | head -n 12 || true)"
  if [ -z "$rules" ]; then
    rules="$(grep -Ei 'open-api|appKey|网关|gateway|禁止通过ip|prefix|前缀' "$readme_file" 2>/dev/null | sed -E 's/\r//;s/^[[:space:]>*-]+//;s/[[:space:]]+/ /g;s/[[:space:]]$//' | head -n 12 || true)"
  fi
  if [ -n "$rules" ]; then
    while IFS= read -r rule; do
      [ -n "$rule" ] || continue
      append_unique_line project_rules "- $rule"
    done <<< "$rules"
  fi
}

readme_module_role() {
  local module="$1"
  [ -n "$readme_file" ] || return 0

  local line role
  line="$(grep -iF -m 1 "$module" "$readme_file" 2>/dev/null || true)"
  [ -n "$line" ] || return 0

  line="$(printf '%s' "$line" | sed -E 's/\r//;s/^[[:space:]>*-]+//;s/[[:space:]]+/ /g;s/^[[:space:]]+//;s/[[:space:]]+$//')"
  role="${line#*$module}"
  role="$(printf '%s' "$role" | sed -E 's/^[[:space:]-]+//;s/[[:space:]]+$//')"
  if [ -n "$role" ]; then
    printf '%s' "$role"
  fi
}

scan_maven_modules() {
  has_file pom.xml || return 0

  local modules
  modules="$(sed -n '/<modules>/,/<\/modules>/p' "$target/pom.xml" | sed -n 's/.*<module>\(.*\)<\/module>.*/\1/p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)"

  if [ -z "$modules" ]; then
    return 0
  fi

  if [ "$lang" = "zh-CN" ]; then
    append_line module_summary "- 根 \`pom.xml\` 声明了 Maven modules："
  else
    append_line module_summary "- Root \`pom.xml\` declares Maven modules:"
  fi

  while IFS= read -r module; do
    [ -n "$module" ] || continue
    local note=""
    local module_path="$target/$module"
    if [ -d "$module_path" ]; then
      if [ -f "$module_path/pom.xml" ]; then
        note="pom.xml"
      fi
      if [ -d "$module_path/src/main" ]; then
        if [ -n "$note" ]; then note="$note, src/main"; else note="src/main"; fi
        if [ "$lang" = "zh-CN" ]; then
          append_line source_layout "- \`$module/src/main\`：Maven module 源码目录。"
        else
          append_line source_layout "- \`$module/src/main\`: Maven module source directory."
        fi
      fi
      if [ -d "$module_path/src/test" ]; then
        if [ -n "$note" ]; then note="$note, src/test"; else note="src/test"; fi
        if [ "$lang" = "zh-CN" ]; then
          append_line test_layout "- \`$module/src/test\`：Maven module 测试目录。"
        else
          append_line test_layout "- \`$module/src/test\`: Maven module test directory."
        fi
      fi
      if [ -d "$module_path/target" ]; then
        if [ -n "$note" ]; then note="$note, target"; else note="target"; fi
        if [ "$lang" = "zh-CN" ]; then
          append_line build_outputs "- \`$module/target\`：检测到 Maven 构建产物目录，通常不应作为源码依据。"
        else
          append_line build_outputs "- \`$module/target\`: Maven build output detected; usually not source of truth."
        fi
      fi
      if [ -z "$note" ]; then
        if [ "$lang" = "zh-CN" ]; then note="目录存在，职责待确认"; else note="directory exists, responsibility needs confirmation"; fi
      fi
    else
      if [ "$lang" = "zh-CN" ]; then note="模块目录未找到"; else note="module directory not found"; fi
    fi

    local role
    role="$(readme_module_role "$module")"
    if [ -n "$role" ]; then
      if [ "$lang" = "zh-CN" ]; then
        note="${note}；README 说明：$role"
      else
        note="$note; README: $role"
      fi
    fi

    append_line module_summary "  - \`$module\`：$note"
    append_line important_paths "- \`$module/\`"
  done <<< "$modules"
}

scan_local_dependencies() {
  local jars
  jars="$(find "$target" -maxdepth 3 \( -path "$target/.git" -o -path "$target/*/target" \) -prune -o -type f -name '*.jar' -print 2>/dev/null | sed "s#^$target/##" | sort | head -n 20 || true)"
  if [ -n "$jars" ]; then
    if [ "$lang" = "zh-CN" ]; then
      append_line local_dependencies "- 检测到仓库内 jar 依赖或构建产物："
    else
      append_line local_dependencies "- Repository-local jar files detected:"
    fi
    while IFS= read -r jar; do
      [ -n "$jar" ] || continue
      append_line local_dependencies "  - \`$jar\`"
    done <<< "$jars"
  fi
}

scan_runtime_configs() {
  local configs
  configs="$(find "$target" -maxdepth 5 \( -path "$target/.git" -o -path "$target/*/target" \) -prune -o -type f \( -name 'application*.yml' -o -name 'application*.yaml' -o -name 'application*.properties' -o -name 'bootstrap*.yml' -o -name 'bootstrap*.yaml' -o -name 'bootstrap*.properties' \) -print 2>/dev/null | sed "s#^$target/##" | sort | head -n 40 || true)"
  if [ -n "$configs" ]; then
    if [ "$lang" = "zh-CN" ]; then
      append_line runtime_configs "- 检测到运行配置文件（按目录聚合）："
    else
      append_line runtime_configs "- Runtime configuration files detected, grouped by directory:"
    fi
    local grouped
    grouped="$(printf '%s\n' "$configs" | awk -F/ '
      {
        file=$NF
        key=""
        for (i = 1; i <= NF; i++) {
          if ($i == "resources" && i >= 3 && $(i-1) == "main" && $(i-2) == "src") {
            key=$1
            for (j = 2; j <= i; j++) key=key "/" $j
            break
          }
        }
        if (key == "") key=(NF > 1 ? $1 : ".")
        pair=key SUBSEP file
        if (seen[pair]++) next
        files[key]=(files[key] ? files[key] ", `" file "`" : "`" file "`")
      }
      END {
        for (key in files) print key "\t" files[key]
      }
    ' | sort)"
    while IFS=$'\t' read -r dir files; do
      [ -n "$dir" ] || continue
      if [ "$lang" = "zh-CN" ]; then
        append_line runtime_configs "  - \`$dir\`：$files"
      else
        append_line runtime_configs "  - \`$dir\`: $files"
      fi
    done <<< "$grouped"
  fi
}

scan_java_entrypoints() {
  local files
  files="$(find "$target" -maxdepth 12 \( -path "$target/.git" -o -path "$target/*/target" \) -prune -o -type f -name '*.java' -print 2>/dev/null | xargs grep -l '@SpringBootApplication' 2>/dev/null | sed "s#^$target/##" | sort | head -n 20 || true)"
  if [ -n "$files" ]; then
    if [ "$lang" = "zh-CN" ]; then
      append_line entrypoints "- 检测到 Spring Boot 启动类："
    else
      append_line entrypoints "- Spring Boot application entrypoints detected:"
    fi
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      append_line entrypoints "  - \`$file\`"
      append_line important_paths "- \`$file\`"
    done <<< "$files"
  fi
}

scan_domain_packages() {
  local dirs
  dirs="$(find "$target" -maxdepth 12 \( -path "$target/.git" -o -path "$target/*/target" \) -prune -o -type f -name '*Controller.java' -print 2>/dev/null | sed "s#^$target/##" | sed 's#/[^/]*$##' | sort -u | head -n 80 || true)"
  if [ -n "$dirs" ]; then
    if [ "$lang" = "zh-CN" ]; then
      append_line domain_map "- 检测到 Controller 候选业务域（按模块聚合）："
    else
      append_line domain_map "- Candidate controller domains detected, grouped by module:"
    fi
    local grouped
    grouped="$(printf '%s\n' "$dirs" | awk -F/ '
      {
        module=$1
        domain=$0
        if (domain ~ /\/controller\//) {
          sub(/^.*\/controller\//, "controller/", domain)
        } else if (domain ~ /\/controller$/) {
          domain="controller"
        } else if (domain ~ /\/openapi\//) {
          sub(/^.*\/openapi\//, "openapi/", domain)
        } else {
          domain=$NF
        }
        pair=module SUBSEP domain
        if (seen[pair]++) next
        count[module]++
        if (count[module] <= 30) {
          domains[module]=(domains[module] ? domains[module] ", `" domain "`" : "`" domain "`")
        } else {
          overflow[module]++
        }
      }
      END {
        for (module in domains) {
          suffix=(overflow[module] ? " (+" overflow[module] " more)" : "")
          print module "\t" domains[module] suffix
        }
      }
    ' | sort)"
    while IFS=$'\t' read -r module domains; do
      [ -n "$module" ] || continue
      if [ "$lang" = "zh-CN" ]; then
        append_line domain_map "  - \`$module\`：$domains"
      else
        append_line domain_map "  - \`$module\`: $domains"
      fi
    done <<< "$grouped"
  fi
}

extract_readme_summary
scan_readme_facts

if has_file package.json; then
  if [ "$lang" = "zh-CN" ]; then
    append_line project_type "- 检测到 JavaScript/TypeScript 包：\`package.json\`。"
  else
    append_line project_type "- JavaScript/TypeScript package detected: \`package.json\`."
  fi
  if has_file pnpm-lock.yaml; then
    install_cmd="pnpm install"
    package_runner="pnpm"
  elif has_file yarn.lock; then
    install_cmd="yarn install"
    package_runner="yarn"
  elif has_file package-lock.json; then
    install_cmd="npm install"
    package_runner="npm"
  else
    install_cmd="npm install"
    package_runner="npm"
  fi
  if json_script_exists dev; then run_cmd="$package_runner run dev"; fi
  if [ -z "$run_cmd" ] && json_script_exists start; then run_cmd="$package_runner start"; fi
  if json_script_exists test; then test_cmd="$package_runner test"; fi
  if json_script_exists build; then build_cmd="$package_runner run build"; fi
  if json_script_exists lint; then lint_cmd="$package_runner run lint"; fi
  if json_script_exists typecheck; then
    if [ -n "$lint_cmd" ]; then lint_cmd="$lint_cmd; $package_runner run typecheck"; else lint_cmd="$package_runner run typecheck"; fi
  fi
fi

if has_file pyproject.toml; then
  if [ "$lang" = "zh-CN" ]; then
    append_line project_type "- 检测到 Python 项目：\`pyproject.toml\`。"
  else
    append_line project_type "- Python project detected: \`pyproject.toml\`."
  fi
  [ -z "$install_cmd" ] && install_cmd="pip install -e ."
  [ -z "$test_cmd" ] && test_cmd="pytest"
elif has_file requirements.txt; then
  if [ "$lang" = "zh-CN" ]; then
    append_line project_type "- 检测到 Python 依赖：\`requirements.txt\`。"
  else
    append_line project_type "- Python dependencies detected: \`requirements.txt\`."
  fi
  [ -z "$install_cmd" ] && install_cmd="pip install -r requirements.txt"
fi

if has_file go.mod; then
  if [ "$lang" = "zh-CN" ]; then
    append_line project_type "- 检测到 Go module：\`go.mod\`。"
  else
    append_line project_type "- Go module detected: \`go.mod\`."
  fi
  [ -z "$test_cmd" ] && test_cmd="go test ./..."
  [ -z "$build_cmd" ] && build_cmd="go build ./..."
fi

if has_file Cargo.toml; then
  if [ "$lang" = "zh-CN" ]; then
    append_line project_type "- 检测到 Rust crate：\`Cargo.toml\`。"
  else
    append_line project_type "- Rust crate detected: \`Cargo.toml\`."
  fi
  [ -z "$test_cmd" ] && test_cmd="cargo test"
  [ -z "$build_cmd" ] && build_cmd="cargo build"
fi

if has_file pom.xml; then
  if [ "$lang" = "zh-CN" ]; then
    append_line project_type "- 检测到 Maven 项目：\`pom.xml\`。"
  else
    append_line project_type "- Maven project detected: \`pom.xml\`."
  fi
  [ -z "$test_cmd" ] && test_cmd="mvn test"
  [ -z "$build_cmd" ] && build_cmd="mvn package"
  scan_maven_modules
fi

if has_file build.gradle || has_file settings.gradle || has_file build.gradle.kts || has_file settings.gradle.kts; then
  if [ "$lang" = "zh-CN" ]; then
    append_line project_type "- 检测到 Gradle 项目。"
  else
    append_line project_type "- Gradle project detected."
  fi
  [ -z "$test_cmd" ] && test_cmd="./gradlew test"
  [ -z "$build_cmd" ] && build_cmd="./gradlew build"
fi

for dir in src app pages components lib packages services server client public; do
  if has_dir "$dir"; then
    if [ "$lang" = "zh-CN" ]; then
      append_line source_layout "- \`$dir/\`：存在。"
    else
      append_line source_layout "- \`$dir/\`: present."
    fi
    append_line important_paths "- \`$dir/\`"
  fi
done

for dir in test tests __tests__ e2e spec specs; do
  if has_dir "$dir"; then
    if [ "$lang" = "zh-CN" ]; then
      append_line test_layout "- \`$dir/\`：存在。"
    else
      append_line test_layout "- \`$dir/\`: present."
    fi
    append_line important_paths "- \`$dir/\`"
  fi
done

if has_dir .github/workflows; then
  if [ "$lang" = "zh-CN" ]; then
    append_line ci_cd "- 检测到 GitHub Actions workflows：\`.github/workflows/\`。"
  else
    append_line ci_cd "- GitHub Actions workflows detected in \`.github/workflows/\`."
  fi
  append_line important_paths "- \`.github/workflows/\`"
fi

if has_file Dockerfile; then
  if [ "$lang" = "zh-CN" ]; then
    append_line ci_cd "- 检测到 Dockerfile：\`Dockerfile\`。"
  else
    append_line ci_cd "- Dockerfile detected: \`Dockerfile\`."
  fi
fi

if has_file docker-compose.yml || has_file docker-compose.yaml; then
  if [ "$lang" = "zh-CN" ]; then
    append_line ci_cd "- 检测到 Docker Compose 配置。"
  else
    append_line ci_cd "- Docker Compose configuration detected."
  fi
fi

for dir in prisma migrations db database; do
  if has_dir "$dir"; then
    if [ "$lang" = "zh-CN" ]; then
      append_line data_stores "- \`$dir/\`：存在。"
    else
      append_line data_stores "- \`$dir/\`: present."
    fi
  fi
done

if grep -Ril "DATABASE_URL\|POSTGRES\|MYSQL\|MONGO" "$target/.env.example" "$target/docker-compose.yml" "$target/docker-compose.yaml" >/dev/null 2>&1; then
  if [ "$lang" = "zh-CN" ]; then
    append_line data_stores "- 检测到数据库相关环境变量或 compose 配置。"
  else
    append_line data_stores "- Database-related environment or compose configuration detected."
  fi
fi

scan_local_dependencies
scan_runtime_configs
scan_java_entrypoints
scan_domain_packages

if [ -z "$project_type" ]; then project_type="$unknown_project"; fi
if [ -z "$source_layout" ]; then source_layout="$no_source"; fi
if [ -z "$test_layout" ]; then test_layout="$no_tests"; fi
if [ -z "$ci_cd" ]; then ci_cd="$no_ci"; fi
if [ -z "$data_stores" ]; then data_stores="$no_datastore"; fi
if [ -z "$external_services" ]; then external_services="$no_external"; fi
if [ -z "$important_paths" ]; then important_paths="$no_paths"; fi
if [ -z "$runtime_stack" ]; then
  if [ "$lang" = "zh-CN" ]; then runtime_stack="- 暂未确认运行时技术栈。"; else runtime_stack="- Runtime stack has not been confirmed yet."; fi
fi
if [ -z "$runtime_configs" ]; then
  if [ "$lang" = "zh-CN" ]; then runtime_configs="- 暂未检测到运行配置文件。"; else runtime_configs="- No runtime configuration files detected."; fi
fi
if [ -z "$entrypoints" ]; then
  if [ "$lang" = "zh-CN" ]; then entrypoints="- 暂未检测到应用启动入口。"; else entrypoints="- No application entrypoints detected."; fi
fi
if [ -z "$project_rules" ]; then
  if [ "$lang" = "zh-CN" ]; then project_rules="- 暂未从 README 或配置文件确认项目级开发规则。"; else project_rules="- No project-level development rules confirmed from README or configuration files."; fi
fi
if [ -z "$domain_map" ]; then
  if [ "$lang" = "zh-CN" ]; then domain_map="- 暂未检测到 Controller 包路径或业务域入口。"; else domain_map="- No controller package paths or domain entry points detected."; fi
fi
if [ "$lang" = "zh-CN" ]; then
  domain_gaps="- Controller 包路径只是候选业务域，首次修改相关业务时应确认真实边界。\n- README 未说明的模块职责，应在实际变更中补充。"
else
  domain_gaps="- Controller package paths are candidate domains; confirm true boundaries during the first related change.\n- Module responsibilities missing from README should be added during real changes."
fi
if [ -z "$module_summary" ]; then
  if [ "$lang" = "zh-CN" ]; then module_summary="- 未检测到 Maven modules。"; else module_summary="- No Maven modules detected."; fi
fi
if [ -z "$local_dependencies" ]; then
  if [ "$lang" = "zh-CN" ]; then local_dependencies="- 未检测到仓库内 jar 依赖。"; else local_dependencies="- No repository-local jar dependencies detected."; fi
fi
if [ -z "$build_outputs" ]; then
  if [ "$lang" = "zh-CN" ]; then build_outputs="- 未检测到构建产物目录。"; else build_outputs="- No build output directories detected."; fi
fi

commands="$(
  command_or_unknown "$label_install" "$install_cmd"
  command_or_unknown "$label_run" "$run_cmd"
  command_or_unknown "$label_test" "$test_cmd"
  command_or_unknown "$label_build" "$build_cmd"
  command_or_unknown "$label_lint" "$lint_cmd"
)"

commands_evidence="$(printf '%s\n' "$commands" | sed 's/^/  /')"
project_type_evidence="$(printf '%s\n' "$project_type" | sed 's/^/  /')"
module_summary_evidence="$(printf '%s\n' "$module_summary" | sed 's/^/  /')"
runtime_stack_evidence="$(printf '%s\n' "$runtime_stack" | sed 's/^/  /')"
build_outputs_evidence="$(printf '%s\n' "$build_outputs" | sed 's/^/  /')"

if [ "$lang" = "zh-CN" ]; then
  if printf '%s\n' "$runtime_stack" | grep -q '暂未确认'; then append_line known_unknowns "- 运行时技术栈。"; fi
  if printf '%s\n' "$module_summary" | grep -q '未检测到'; then append_line known_unknowns "- 模块边界。"; fi
  if printf '%s\n' "$ci_cd" | grep -q '暂未确认'; then append_line known_unknowns "- 部署模型。"; fi
  append_line known_unknowns "- 数据所有权。"

  [ -z "$run_cmd" ] && append_line tech_debt_investigation "- 运行命令/profile 待确认。"
  if printf '%s\n' "$ci_cd" | grep -q '暂未确认'; then append_line tech_debt_investigation "- CI/CD 或部署入口待确认。"; fi
  append_line tech_debt_investigation "- 数据所有权待确认。"
  if printf '%s\n' "$domain_map" | grep -q '暂未检测到'; then append_line tech_debt_investigation "- 业务域入口待确认。"; else append_line tech_debt_investigation "- Controller 候选业务域需要在首次相关变更中确认。"; fi
else
  if printf '%s\n' "$runtime_stack" | grep -q 'not been confirmed'; then append_line known_unknowns "- Runtime stack."; fi
  if printf '%s\n' "$module_summary" | grep -q 'No Maven modules'; then append_line known_unknowns "- Module boundaries."; fi
  if printf '%s\n' "$ci_cd" | grep -q 'not been confirmed'; then append_line known_unknowns "- Deployment model."; fi
  append_line known_unknowns "- Data ownership."

  [ -z "$run_cmd" ] && append_line tech_debt_investigation "- Run command/profile needs confirmation."
  if printf '%s\n' "$ci_cd" | grep -q 'not been confirmed'; then append_line tech_debt_investigation "- CI/CD or deployment entry point needs confirmation."; fi
  append_line tech_debt_investigation "- Data ownership needs confirmation."
  if printf '%s\n' "$domain_map" | grep -q 'No controller'; then append_line tech_debt_investigation "- Domain entry points need confirmation."; else append_line tech_debt_investigation "- Candidate controller domains need confirmation during the first related change."; fi
fi

if [ "$lang" = "zh-CN" ]; then
  project_summary="已初始化为适合 agent 辅助开发的项目。以下事实来自仓库文件中可确认的信息。"
  if [ "$project_type" = "$unknown_project" ]; then
    project_summary="空项目或未识别项目。首次实现变更后，请用观察到的事实替换占位内容。"
  fi
  if [ -n "$readme_summary" ]; then
    project_summary="$project_summary\n\n$readme_summary"
  fi
else
  project_summary="Initialized for agent-assisted development. The facts below were inferred from repository files where possible."
  if [ "$project_type" = "$unknown_project" ]; then
    project_summary="Blank or unrecognized project. Replace placeholders with observed facts after the first implementation change."
  fi
  if [ -n "$readme_summary" ]; then
    project_summary="$project_summary\n\n$readme_summary"
  fi
fi

run_commands="$(command_or_unknown "$label_run" "$run_cmd")"
test_commands="$(command_or_unknown "$label_test" "$test_cmd")"
build_commands="$(command_or_unknown "$label_build" "$build_cmd")"

if [ "$lang" = "zh-CN" ]; then
  architecture_overview="当前推断的项目形态：\n\n$project_type"
  if [ -n "$module_summary" ]; then
    architecture_overview="$architecture_overview\n\n$module_summary"
  fi
  architecture_runtime="$runtime_stack\n\n$entrypoints\n\n$runtime_configs"
  architecture_boundaries="- Frontend：在确认源码结构和框架文件后再填写。\n- Backend：基于 Maven modules、README 模块说明和源码目录继续确认。\n- Data layer：见 agent map 的数据存储部分。\n- External integrations：见 agent map 的外部服务部分。"
  if [ -n "$local_dependencies" ]; then
    architecture_boundaries="$architecture_boundaries\n\n$local_dependencies"
  fi
  quality_summary="由 \`\$spec-to-ship init\` 生成的初始基线。只根据证据更新评分。"
  quality_build_test="- 状态：已初始化。\n- 证据：\n$commands_evidence"
  if [ -n "$build_outputs" ]; then
    quality_build_test="$quality_build_test\n$build_outputs_evidence"
  fi
  quality_documentation="- 状态：已初始化。\n- 证据：项目级 agent 文档由 \`\$spec-to-ship init\` 创建。"
  quality_architecture="- 状态：部分确认。\n- 证据：\n$project_type_evidence\n$runtime_stack_evidence"
  if [ -n "$module_summary" ]; then
    quality_architecture="$quality_architecture\n$module_summary_evidence"
  fi
  quality_release="- 状态：未知。\n- 证据：除下方 CI/CD 信息外，暂未确认发布流程。\n$ci_cd"
  quality_agent_readability="- 状态：已初始化。\n- 证据：\`AGENTS.md\`、\`docs/agent-map.md\` 和相关文档已存在。"
  quality_gaps="- 确认所有标记为未建立的命令。\n- 随着实现推进，用观察到的事实替换推断占位。\n- 将重要决策记录到 \`docs/decisions/\`。"
else
  architecture_overview="Current inferred project shape:\n\n$project_type"
  if [ -n "$module_summary" ]; then
    architecture_overview="$architecture_overview\n\n$module_summary"
  fi
  architecture_runtime="$runtime_stack\n\n$entrypoints\n\n$runtime_configs"
  architecture_boundaries="- Frontend: infer from source layout and framework files when confirmed.\n- Backend: continue confirming from Maven modules, README module notes, and source directories.\n- Data layer: see Data Stores in the agent map.\n- External integrations: see External Services in the agent map."
  if [ -n "$local_dependencies" ]; then
    architecture_boundaries="$architecture_boundaries\n\n$local_dependencies"
  fi
  quality_summary="Initial baseline generated by \`\$spec-to-ship init\`. Update scores only with evidence."
  quality_build_test="- Status: initialized.\n- Evidence:\n$commands_evidence"
  if [ -n "$build_outputs" ]; then
    quality_build_test="$quality_build_test\n$build_outputs_evidence"
  fi
  quality_documentation="- Status: initialized.\n- Evidence: project agent docs were created by \`\$spec-to-ship init\`."
  quality_architecture="- Status: partial.\n- Evidence:\n$project_type_evidence\n$runtime_stack_evidence"
  if [ -n "$module_summary" ]; then
    quality_architecture="$quality_architecture\n$module_summary_evidence"
  fi
  quality_release="- Status: unknown.\n- Evidence: release process has not been confirmed yet unless CI/CD is listed below.\n$ci_cd"
  quality_agent_readability="- Status: initialized.\n- Evidence: \`AGENTS.md\`, \`docs/agent-map.md\`, and related docs exist."
  quality_gaps="- Confirm any command marked not established.\n- Replace inferred placeholders with observed facts as implementation progresses.\n- Record important decisions in \`docs/decisions/\`."
fi

render_template() {
  local src="$1"
  local dest="$2"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "{{PROJECT_SUMMARY}}") printf '%b\n' "$project_summary" ;;
      "{{RUN_COMMANDS}}") printf '%b\n' "$run_commands" ;;
      "{{TEST_COMMANDS}}") printf '%b\n' "$test_commands" ;;
      "{{BUILD_COMMANDS}}") printf '%b\n' "$build_commands" ;;
      "{{IMPORTANT_PATHS}}") printf '%b\n' "$important_paths" ;;
      "{{PROJECT_TYPE}}") printf '%b\n' "$project_type" ;;
      "{{SOURCE_LAYOUT}}") printf '%b\n' "$source_layout" ;;
      "{{MODULE_SUMMARY}}") printf '%b\n' "$module_summary" ;;
      "{{RUNTIME_STACK}}") printf '%b\n' "$runtime_stack" ;;
      "{{ENTRYPOINTS}}") printf '%b\n' "$entrypoints" ;;
      "{{RUNTIME_CONFIGS}}") printf '%b\n' "$runtime_configs" ;;
      "{{PROJECT_RULES}}") printf '%b\n' "$project_rules" ;;
      "{{DOMAIN_MAP}}") printf '%b\n' "$domain_map" ;;
      "{{DOMAIN_GAPS}}") printf '%b\n' "$domain_gaps" ;;
      "{{TECH_DEBT_INVESTIGATION}}") printf '%b\n' "$tech_debt_investigation" ;;
      "{{TEST_LAYOUT}}") printf '%b\n' "$test_layout" ;;
      "{{COMMANDS}}") printf '%b\n' "$commands" ;;
      "{{CI_CD}}") printf '%b\n' "$ci_cd" ;;
      "{{DATA_STORES}}") printf '%b\n' "$data_stores" ;;
      "{{LOCAL_DEPENDENCIES}}") printf '%b\n' "$local_dependencies" ;;
      "{{BUILD_OUTPUTS}}") printf '%b\n' "$build_outputs" ;;
      "{{EXTERNAL_SERVICES}}") printf '%b\n' "$external_services" ;;
      "{{ARCHITECTURE_OVERVIEW}}") printf '%b\n' "$architecture_overview" ;;
      "{{ARCHITECTURE_RUNTIME}}") printf '%b\n' "$architecture_runtime" ;;
      "{{ARCHITECTURE_BOUNDARIES}}") printf '%b\n' "$architecture_boundaries" ;;
      "{{KNOWN_UNKNOWNS}}") printf '%b\n' "$known_unknowns" ;;
      "{{QUALITY_SUMMARY}}") printf '%b\n' "$quality_summary" ;;
      "{{QUALITY_BUILD_TEST}}") printf '%b\n' "$quality_build_test" ;;
      "{{QUALITY_DOCUMENTATION}}") printf '%b\n' "$quality_documentation" ;;
      "{{QUALITY_ARCHITECTURE}}") printf '%b\n' "$quality_architecture" ;;
      "{{QUALITY_RELEASE}}") printf '%b\n' "$quality_release" ;;
      "{{QUALITY_AGENT_READABILITY}}") printf '%b\n' "$quality_agent_readability" ;;
      "{{QUALITY_GAPS}}") printf '%b\n' "$quality_gaps" ;;
      *)
        line="${line//\{\{PROJECT_NAME\}\}/$project_name}"
        line="${line//\{\{GENERATED_AT\}\}/$generated_at}"
        line="${line//\{\{LANGUAGE\}\}/$lang}"
        printf '%s\n' "$line"
        ;;
    esac
  done < "$src" > "$dest"
}

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

  render_template "$src" "$dest"
  echo "CREATE $rel"
  created=$((created + 1))
done < <(find "$template_dir" -type f | sort)

echo "Initialized agent docs in $target"
echo "Created: $created"
echo "Skipped: $skipped"
