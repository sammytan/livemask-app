#!/usr/bin/env bash
set -uo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${APP_DIR}/.local-dev"
LOG_DIR="${STATE_DIR}/logs"
RUN_DIR="${STATE_DIR}/run"
mkdir -p "${LOG_DIR}" "${RUN_DIR}"

command="${1:-}"
if [[ -z "${command}" ]]; then
  command="help"
else
  shift || true
fi

targets=""
backend_url="${API_BASE_URL:-http://127.0.0.1:${LIVEMASK_BACKEND_HTTP_PORT:-18080}}"
web_port="${LIVEMASK_APP_WEB_PORT:-3003}"
device_id=""
foreground=false
continue_on_error=true

usage() {
  cat <<'EOF'
Usage:
  bash scripts/local-app.sh start   [--target macos|ios|android|linux|windows|web]
  bash scripts/local-app.sh build   [--targets macos,ios|all]
  bash scripts/local-app.sh stop    [--targets macos,ios|all]
  bash scripts/local-app.sh restart [--target macos|ios|android|linux|windows|web]
  bash scripts/local-app.sh status
  bash scripts/local-app.sh logs    [--target macos|ios|android|linux|windows|web]
  bash scripts/local-app.sh doctor

Shortcuts:
  --macos --ios --android --linux --windows --web
  --all                  Same as --targets all.
  --targets LIST         Comma-separated target queue.
  --foreground           Run the selected start command in the foreground.
  --device-id ID         Flutter device id for ios/android run.
  --fail-fast            Stop queued builds after the first failure.

Environment:
  API_BASE_URL                 Backend URL. Default: http://127.0.0.1:18080
  LIVEMASK_BACKEND_HTTP_PORT   Used when API_BASE_URL is unset.
  LIVEMASK_APP_WEB_PORT        Flutter web-server port. Default: 3003
  LIVEMASK_APP_IOS_SAFE_WORKDIR
                               iOS build/run mirror directory. Default: /private/tmp/livemask-app-ios-$USER
  LIVEMASK_APP_DISABLE_IOS_SAFE_WORKDIR
                               Set to 1 to build iOS directly in the repo.

Notes:
  - App runs locally, not in Docker, so Flutter/Dart/Xcode errors stay visible.
  - On Apple Silicon Macs, macOS and iOS are the primary local verification targets.
  - Android requires Android SDK/toolchain.
  - Linux must be built on Linux.
  - Windows must be built on Windows, for example inside Parallels Desktop.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|--targets)
      targets="$2"
      shift 2
      ;;
    --all)
      targets="all"
      shift
      ;;
    --macos|--ios|--android|--linux|--windows|--web)
      value="${1#--}"
      if [[ -z "${targets}" ]]; then
        targets="${value}"
      else
        targets="${targets},${value}"
      fi
      shift
      ;;
    --foreground)
      foreground=true
      shift
      ;;
    --fail-fast)
      continue_on_error=false
      shift
      ;;
    --backend-url)
      backend_url="$2"
      shift 2
      ;;
    --device-id)
      device_id="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${targets}" ]]; then
  targets="macos"
fi

expand_targets() {
  local raw="$1"
  if [[ "${raw}" == "all" ]]; then
    printf '%s\n' macos ios android linux windows web
    return 0
  fi
  local item
  IFS=',' read -r -a items <<<"${raw}"
  for item in "${items[@]}"; do
    item="$(echo "${item}" | tr '[:upper:]' '[:lower:]' | xargs)"
    [[ -n "${item}" ]] && printf '%s\n' "${item}"
  done
}

host_os() {
  case "$(uname -s 2>/dev/null || echo unknown)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

validate_target() {
  case "$1" in
    macos|ios|android|linux|windows|web) return 0 ;;
    *)
      echo "Unknown target: $1" >&2
      return 2
      ;;
  esac
}

require_flutter() {
  if ! command -v flutter >/dev/null 2>&1; then
    cat >&2 <<'EOF'
Flutter SDK is not available in PATH.

Install Flutter locally and reopen the terminal, then verify:
  flutter doctor

On macOS, also install full Xcode and select it:
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept
EOF
    return 127
  fi
}

target_supported_on_host() {
  local target="$1"
  local os
  os="$(host_os)"
  case "${target}" in
    macos|ios)
      [[ "${os}" == "macos" ]]
      ;;
    linux)
      [[ "${os}" == "linux" ]]
      ;;
    windows)
      [[ "${os}" == "windows" ]]
      ;;
    android|web)
      return 0
      ;;
  esac
}

unsupported_message() {
  local target="$1"
  case "${target}" in
    macos|ios)
      echo "${target}: requires macOS + full Xcode."
      ;;
    linux)
      echo "linux: requires a Linux host."
      ;;
    windows)
      echo "windows: requires a Windows host, e.g. Parallels Desktop Windows VM."
      ;;
    android)
      echo "android: requires Android SDK/toolchain configured in flutter doctor."
      ;;
  esac
}

ensure_target_scaffold() {
  local target="$1"
  local platform="${target}"
  [[ "${target}" == "web" ]] && platform="web"
  if [[ ! -d "${APP_DIR}/${platform}" ]]; then
    echo "${platform}/ target is missing; generating Flutter scaffold..."
    (cd "${APP_DIR}" && flutter create --platforms="${platform}" .)
  fi
}

clean_apple_extended_attributes() {
  local target="$1"
  case "${target}" in
    macos|ios)
      for path in "${APP_DIR}/macos" "${APP_DIR}/ios" "${APP_DIR}/build/macos" "${APP_DIR}/build/ios"; do
        if [[ -e "${path}" ]]; then
          xattr -cr "${path}" 2>/dev/null || true
          find "${path}" -name .DS_Store -delete 2>/dev/null || true
        fi
      done
      ;;
  esac
}

execution_work_dir_for() {
  local target="$1"
  if [[ "${target}" != "ios" || "$(host_os)" != "macos" || "${LIVEMASK_APP_DISABLE_IOS_SAFE_WORKDIR:-}" == "1" ]]; then
    printf '%s\n' "${APP_DIR}"
    return 0
  fi

  local safe_dir="${LIVEMASK_APP_IOS_SAFE_WORKDIR:-/private/tmp/livemask-app-ios-${USER:-user}}"
  mkdir -p "${safe_dir}"
  echo "Using iOS safe workdir: ${safe_dir}" >&2
  rsync -a --delete \
    --exclude .git \
    --exclude build \
    --exclude .dart_tool \
    --exclude .local-dev \
    "${APP_DIR}/" "${safe_dir}/"
  xattr -cr "${safe_dir}" 2>/dev/null || true
  find "${safe_dir}" -name .DS_Store -delete 2>/dev/null || true
  printf '%s\n' "${safe_dir}"
}

pid_file_for() {
  printf '%s/%s.pid' "${RUN_DIR}" "$1"
}

log_file_for() {
  printf '%s/%s.log' "${LOG_DIR}" "$1"
}

is_running_target() {
  local target="$1"
  local pid_file
  pid_file="$(pid_file_for "${target}")"
  [[ -f "${pid_file}" ]] || return 1
  local pid
  pid="$(cat "${pid_file}" 2>/dev/null || true)"
  [[ -n "${pid}" ]] || return 1
  kill -0 "${pid}" >/dev/null 2>&1
}

stop_target() {
  local target="$1"
  local pid_file
  pid_file="$(pid_file_for "${target}")"
  if is_running_target "${target}"; then
    local pid
    pid="$(cat "${pid_file}")"
    echo "Stopping LiveMask App ${target} (pid=${pid})..."
    kill "${pid}" >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
      kill -0 "${pid}" >/dev/null 2>&1 || break
      sleep 0.2
    done
    kill -9 "${pid}" >/dev/null 2>&1 || true
  fi
  rm -f "${pid_file}"
}

flutter_defines() {
  printf '%s\n' \
    "--dart-define=AUTH_CLIENT_MODE=real" \
    "--dart-define=API_BASE_URL=${backend_url}"
}

build_command_for() {
  local target="$1"
  case "${target}" in
    macos)
      printf '%s\n' \
        "flutter config --enable-macos-desktop" \
        "flutter pub get" \
        "flutter build macos $(flutter_defines | xargs)"
      ;;
    ios)
      printf '%s\n' \
        "flutter pub get" \
        "flutter build ios --simulator --no-codesign $(flutter_defines | xargs)"
      ;;
    android)
      printf '%s\n' \
        "flutter pub get" \
        "flutter build apk --debug $(flutter_defines | xargs)"
      ;;
    linux)
      printf '%s\n' \
        "flutter config --enable-linux-desktop" \
        "flutter pub get" \
        "flutter build linux $(flutter_defines | xargs)"
      ;;
    windows)
      printf '%s\n' \
        "flutter config --enable-windows-desktop" \
        "flutter pub get" \
        "flutter build windows $(flutter_defines | xargs)"
      ;;
    web)
      printf '%s\n' \
        "flutter config --enable-web" \
        "flutter pub get" \
        "flutter build web $(flutter_defines | xargs)"
      ;;
  esac
}

start_command_for() {
  local target="$1"
  local run_device="${target}"
  if [[ -n "${device_id}" ]]; then
    run_device="${device_id}"
  fi
  case "${target}" in
    macos)
      printf '%s\n' \
        "flutter config --enable-macos-desktop" \
        "flutter pub get" \
        "flutter run -d macos $(flutter_defines | xargs)"
      ;;
    ios)
      printf '%s\n' \
        "flutter pub get" \
        "flutter run -d ${run_device} $(flutter_defines | xargs)"
      ;;
    android)
      printf '%s\n' \
        "flutter pub get" \
        "flutter run -d ${run_device} $(flutter_defines | xargs)"
      ;;
    linux)
      printf '%s\n' \
        "flutter config --enable-linux-desktop" \
        "flutter pub get" \
        "flutter run -d linux $(flutter_defines | xargs)"
      ;;
    windows)
      printf '%s\n' \
        "flutter config --enable-windows-desktop" \
        "flutter pub get" \
        "flutter run -d windows $(flutter_defines | xargs)"
      ;;
    web)
      printf '%s\n' \
        "flutter config --enable-web" \
        "flutter pub get" \
        "flutter run -d web-server --web-hostname 127.0.0.1 --web-port ${web_port} $(flutter_defines | xargs)"
      ;;
  esac
}

execute_command_queue() {
  local command_kind="$1"
  local target="$2"
  local log_file
  log_file="$(log_file_for "${target}")"
  : >"${log_file}"

  validate_target "${target}" || return $?
  if ! target_supported_on_host "${target}"; then
    unsupported_message "${target}" | tee -a "${log_file}"
    return 78
  fi
  require_flutter || return $?

  ensure_target_scaffold "${target}" || return $?
  clean_apple_extended_attributes "${target}"

  local generator
  if [[ "${command_kind}" == "build" ]]; then
    generator="build_command_for"
  else
    generator="start_command_for"
  fi

  local work_dir
  work_dir="$(execution_work_dir_for "${target}")" || return $?

  if [[ "${foreground}" == "true" || "${command_kind}" == "build" ]]; then
    (
      cd "${work_dir}" || exit 1
      while IFS= read -r line; do
        echo "+ ${line}"
        eval "${line}"
      done < <("${generator}" "${target}")
    ) 2>&1 | tee -a "${log_file}"
    return "${PIPESTATUS[0]}"
  fi

  (
    cd "${work_dir}" || exit 1
    while IFS= read -r line; do
      echo "+ ${line}"
      eval "${line}"
    done < <("${generator}" "${target}")
  ) >>"${log_file}" 2>&1 &
  echo "$!" >"$(pid_file_for "${target}")"
  sleep 2
  if ! is_running_target "${target}"; then
    echo "LiveMask App ${target} failed to start. Last log lines:" >&2
    tail -n 80 "${log_file}" >&2 || true
    rm -f "$(pid_file_for "${target}")"
    return 1
  fi
  echo "LiveMask App ${target} started (pid=$(cat "$(pid_file_for "${target}")"))."
}

run_for_targets() {
  local action="$1"
  local failed=0
  local target
  while IFS= read -r target; do
    [[ -n "${target}" ]] || continue
    echo "== ${action}: ${target} =="
    case "${action}" in
      build)
        execute_command_queue build "${target}" || failed=1
        ;;
      start)
        execute_command_queue start "${target}" || failed=1
        ;;
      restart)
        stop_target "${target}"
        execute_command_queue start "${target}" || failed=1
        ;;
      stop)
        validate_target "${target}" || failed=1
        stop_target "${target}"
        ;;
    esac
    if [[ "${failed}" -ne 0 && "${continue_on_error}" == "false" ]]; then
      return "${failed}"
    fi
  done < <(expand_targets "${targets}")
  return "${failed}"
}

status_all() {
  local target
  for target in macos ios android linux windows web; do
    if is_running_target "${target}"; then
      echo "${target}: running (pid=$(cat "$(pid_file_for "${target}")")) logs=$(log_file_for "${target}")"
    else
      echo "${target}: stopped"
    fi
  done
}

case "${command}" in
  build)
    run_for_targets build
    ;;
  start)
    run_for_targets start
    ;;
  stop)
    run_for_targets stop
    ;;
  restart)
    run_for_targets restart
    ;;
  status)
    status_all
    ;;
  logs)
    first_target="$(expand_targets "${targets}" | head -n 1)"
    touch "$(log_file_for "${first_target}")"
    tail -n 120 -f "$(log_file_for "${first_target}")"
    ;;
  doctor)
    if command -v flutter >/dev/null 2>&1; then
      flutter doctor -v
    else
      echo "flutter: not found"
    fi
    echo
    if command -v xcodebuild >/dev/null 2>&1; then
      xcodebuild -version || true
      xcode-select -p || true
    else
      echo "xcodebuild: not found"
    fi
    echo
    echo "Host OS: $(host_os)"
    echo "Supported here:"
    for target in macos ios android linux windows web; do
      if target_supported_on_host "${target}"; then
        echo "- ${target}"
      else
        echo "- ${target}: $(unsupported_message "${target}")"
      fi
    done
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: ${command}" >&2
    usage >&2
    exit 2
    ;;
esac
