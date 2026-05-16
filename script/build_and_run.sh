#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

targets="macos"
command="restart"
foreground=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    build|start|restart|stop|status|doctor)
      command="$1"
      shift
      ;;
    --target|--targets)
      targets="$2"
      shift 2
      ;;
    --web)
      targets="web"
      shift
      ;;
    --macos)
      targets="macos"
      shift
      ;;
    --ios|--android|--linux|--windows|--all)
      targets="${1#--}"
      shift
      ;;
    --foreground|--logs|--telemetry|--debug)
      # Flutter owns the interactive run/debug session; keep these flags
      # accepted so Codex/macOS run workflows have one stable entrypoint.
      foreground=true
      shift
      ;;
    --verify)
      bash "${APP_DIR}/scripts/local-app.sh" status
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "${command}" == "status" || "${command}" == "doctor" ]]; then
  exec bash "${APP_DIR}/scripts/local-app.sh" "${command}"
fi

args=("${command}" --targets "${targets}")
if [[ "${foreground}" == "true" ]]; then
  args+=(--foreground)
fi

exec bash "${APP_DIR}/scripts/local-app.sh" "${args[@]}"
