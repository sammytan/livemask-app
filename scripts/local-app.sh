#!/usr/bin/env bash
set -euo pipefail

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

target="macos"
backend_url="${API_BASE_URL:-http://127.0.0.1:${LIVEMASK_BACKEND_HTTP_PORT:-18080}}"
web_port="${LIVEMASK_APP_WEB_PORT:-3003}"
foreground=false

usage() {
  cat <<'EOF'
Usage:
  bash scripts/local-app.sh start   [--target macos|web] [--foreground]
  bash scripts/local-app.sh stop    [--target macos|web]
  bash scripts/local-app.sh restart [--target macos|web]
  bash scripts/local-app.sh status
  bash scripts/local-app.sh logs    [--target macos|web]
  bash scripts/local-app.sh doctor

Environment:
  API_BASE_URL                 Backend URL. Default: http://127.0.0.1:18080
  LIVEMASK_BACKEND_HTTP_PORT   Used when API_BASE_URL is unset.
  LIVEMASK_APP_WEB_PORT        Flutter web-server port. Default: 3003

Notes:
  - macos is the default target on Apple Silicon development machines.
  - App runs locally, not in Docker, so Flutter/Dart/Xcode errors stay visible.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="$2"
      shift 2
      ;;
    --web)
      target="web"
      shift
      ;;
    --macos)
      target="macos"
      shift
      ;;
    --foreground)
      foreground=true
      shift
      ;;
    --backend-url)
      backend_url="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "${target}" in
  macos|web) ;;
  *)
    echo "Unknown target: ${target}" >&2
    usage >&2
    exit 2
    ;;
esac

pid_file="${RUN_DIR}/${target}.pid"
log_file="${LOG_DIR}/${target}.log"

require_flutter() {
  if ! command -v flutter >/dev/null 2>&1; then
    cat >&2 <<'EOF'
Flutter SDK is not available in PATH.

Install Flutter locally and reopen the terminal, then verify:
  flutter doctor

On macOS, also install full Xcode and select it:
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
EOF
    exit 127
  fi
}

ensure_macos_target() {
  if [[ ! -d "${APP_DIR}/macos" ]]; then
    echo "macos/ target is missing; generating Flutter macOS scaffold..."
    (cd "${APP_DIR}" && flutter create --platforms=macos .)
  fi
}

is_running() {
  [[ -f "${pid_file}" ]] || return 1
  local pid
  pid="$(cat "${pid_file}" 2>/dev/null || true)"
  [[ -n "${pid}" ]] || return 1
  kill -0 "${pid}" >/dev/null 2>&1
}

stop_target() {
  if is_running; then
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

run_command() {
  case "${target}" in
    macos)
      ensure_macos_target
      printf '%s\n' \
        "flutter config --enable-macos-desktop" \
        "flutter pub get" \
        "flutter run -d macos --dart-define=AUTH_CLIENT_MODE=real --dart-define=API_BASE_URL=${backend_url}"
      ;;
    web)
      printf '%s\n' \
        "flutter config --enable-web" \
        "flutter pub get" \
        "flutter run -d web-server --web-hostname 127.0.0.1 --web-port ${web_port} --dart-define=AUTH_CLIENT_MODE=real --dart-define=API_BASE_URL=${backend_url}"
      ;;
  esac
}

start_target() {
  require_flutter
  if is_running; then
    echo "LiveMask App ${target} is already running (pid=$(cat "${pid_file}"))."
    echo "Logs: ${log_file}"
    return 0
  fi

  echo "Starting LiveMask App ${target} against ${backend_url}..."
  echo "Logs: ${log_file}"
  : >"${log_file}"

  if [[ "${foreground}" == "true" ]]; then
    (
      cd "${APP_DIR}"
      while IFS= read -r line; do
        eval "${line}"
      done < <(run_command)
    )
    return 0
  fi

  (
    cd "${APP_DIR}"
    while IFS= read -r line; do
      echo "+ ${line}"
      eval "${line}"
    done < <(run_command)
  ) >>"${log_file}" 2>&1 &
  echo "$!" >"${pid_file}"
  sleep 2
  if ! is_running; then
    echo "LiveMask App ${target} failed to start. Last log lines:" >&2
    tail -n 80 "${log_file}" >&2 || true
    rm -f "${pid_file}"
    exit 1
  fi
  echo "LiveMask App ${target} started (pid=$(cat "${pid_file}"))."
}

case "${command}" in
  start)
    start_target
    ;;
  stop)
    stop_target
    ;;
  restart)
    stop_target
    start_target
    ;;
  status)
    for t in macos web; do
      pid_file="${RUN_DIR}/${t}.pid"
      log_file="${LOG_DIR}/${t}.log"
      target="${t}"
      if is_running; then
        echo "${t}: running (pid=$(cat "${pid_file}")) logs=${log_file}"
      else
        echo "${t}: stopped"
      fi
    done
    ;;
  logs)
    touch "${log_file}"
    tail -n 120 -f "${log_file}"
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

