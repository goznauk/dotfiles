#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  ./setup.sh [ubuntu|macos] [options]

Targets:
  ubuntu    Run Ubuntu setup
  macos     Run macOS setup

Options are passed to the target setup script.
Use ./Ubuntu/setup-ubuntu.sh --help for Ubuntu options.
USAGE
}

target="auto"
args=()

for arg in "$@"; do
  case "$arg" in
    ubuntu|--ubuntu)
      target="ubuntu"
      ;;
    macos|--macos)
      target="macos"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      args+=("$arg")
      ;;
  esac
done

if [[ "$target" == "auto" ]]; then
  case "$(uname -s)" in
    Linux)
      target="ubuntu"
      ;;
    Darwin)
      target="macos"
      ;;
    *)
      printf 'Unsupported OS: %s\n' "$(uname -s)" >&2
      exit 1
      ;;
  esac
fi

case "$target" in
  ubuntu)
    exec "$ROOT_DIR/Ubuntu/setup-ubuntu.sh" "${args[@]}"
    ;;
  macos)
    ENVPATH="$ROOT_DIR/.env" exec "$ROOT_DIR/MacOS/setup-mac.sh" "${args[@]}"
    ;;
esac
