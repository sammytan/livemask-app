#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

target="macos"
foreground=false

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

args=(restart --target "${target}")
if [[ "${foreground}" == "true" ]]; then
  args+=(--foreground)
fi

exec bash "${APP_DIR}/scripts/local-app.sh" "${args[@]}"

