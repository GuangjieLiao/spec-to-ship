#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  spec-to-ship-init.sh [target-dir] [--force] [--lang en|zh-CN]

Initializes project-level agent docs from bundled templates.
By default, existing files are preserved.
The initializer scans the target project and records only facts it can infer from files.
EOF
}

target="."
force="false"
lang="en"

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
external_services="$no_external"
important_paths=""

install_cmd=""
run_cmd=""
test_cmd=""
build_cmd=""
lint_cmd=""

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

if [ -z "$project_type" ]; then project_type="$unknown_project"; fi
if [ -z "$source_layout" ]; then source_layout="$no_source"; fi
if [ -z "$test_layout" ]; then test_layout="$no_tests"; fi
if [ -z "$ci_cd" ]; then ci_cd="$no_ci"; fi
if [ -z "$data_stores" ]; then data_stores="$no_datastore"; fi
if [ -z "$important_paths" ]; then important_paths="$no_paths"; fi

commands="$(
  command_or_unknown "$label_install" "$install_cmd"
  command_or_unknown "$label_run" "$run_cmd"
  command_or_unknown "$label_test" "$test_cmd"
  command_or_unknown "$label_build" "$build_cmd"
  command_or_unknown "$label_lint" "$lint_cmd"
)"

if [ "$lang" = "zh-CN" ]; then
  project_summary="已初始化为适合 agent 辅助开发的项目。以下事实来自仓库文件中可确认的信息。"
  if [ "$project_type" = "$unknown_project" ]; then
    project_summary="空项目或未识别项目。首次实现变更后，请用观察到的事实替换占位内容。"
  fi
else
  project_summary="Initialized for agent-assisted development. The facts below were inferred from repository files where possible."
  if [ "$project_type" = "$unknown_project" ]; then
    project_summary="Blank or unrecognized project. Replace placeholders with observed facts after the first implementation change."
  fi
fi

run_commands="$(command_or_unknown "$label_run" "$run_cmd")"
test_commands="$(command_or_unknown "$label_test" "$test_cmd")"
build_commands="$(command_or_unknown "$label_build" "$build_cmd")"

if [ "$lang" = "zh-CN" ]; then
  architecture_overview="当前推断的项目形态：\n\n$project_type"
  architecture_boundaries="- Frontend：在确认源码结构和框架文件后再填写。\n- Backend：在确认 service/server 目录或后端框架文件后再填写。\n- Data layer：$data_stores\n- External integrations：暂未确认。"
  quality_summary="由 \`\$spec-to-ship init\` 生成的初始基线。只根据证据更新评分。"
  quality_build_test="- 状态：已初始化。\n- 证据：\n$commands"
  quality_documentation="- 状态：已初始化。\n- 证据：项目级 agent 文档由 \`\$spec-to-ship init\` 创建。"
  quality_architecture="- 状态：部分确认。\n- 证据：\n$project_type"
  quality_release="- 状态：未知。\n- 证据：除下方 CI/CD 信息外，暂未确认发布流程。\n$ci_cd"
  quality_agent_readability="- 状态：已初始化。\n- 证据：\`AGENTS.md\`、\`docs/agent-map.md\` 和相关文档已存在。"
  quality_gaps="- 确认所有标记为未建立的命令。\n- 随着实现推进，用观察到的事实替换推断占位。\n- 将重要决策记录到 \`docs/decisions/\`。"
else
  architecture_overview="Current inferred project shape:\n\n$project_type"
  architecture_boundaries="- Frontend: infer from source layout and framework files when confirmed.\n- Backend: infer from service/server directories or backend framework files when confirmed.\n- Data layer: $data_stores\n- External integrations: not confirmed."
  quality_summary="Initial baseline generated by \`\$spec-to-ship init\`. Update scores only with evidence."
  quality_build_test="- Status: initialized.\n- Evidence:\n$commands"
  quality_documentation="- Status: initialized.\n- Evidence: project agent docs were created by \`\$spec-to-ship init\`."
  quality_architecture="- Status: partial.\n- Evidence:\n$project_type"
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
      "{{TEST_LAYOUT}}") printf '%b\n' "$test_layout" ;;
      "{{COMMANDS}}") printf '%b\n' "$commands" ;;
      "{{CI_CD}}") printf '%b\n' "$ci_cd" ;;
      "{{DATA_STORES}}") printf '%b\n' "$data_stores" ;;
      "{{EXTERNAL_SERVICES}}") printf '%b\n' "$external_services" ;;
      "{{ARCHITECTURE_OVERVIEW}}") printf '%b\n' "$architecture_overview" ;;
      "{{ARCHITECTURE_BOUNDARIES}}") printf '%b\n' "$architecture_boundaries" ;;
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
