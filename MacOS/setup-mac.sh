#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVPATH="${ENVPATH:-$ROOT_DIR/.env}"
YES=0

usage() {
  cat <<'USAGE'
Usage:
  ./MacOS/setup-mac.sh [options]

Options:
  -y, --yes   Run without confirmation prompts
  -h, --help  Show this help
USAGE
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -y|--yes)
      YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -r "$ENVPATH" ]]; then
  printf 'Missing environment file: %s\n' "$ENVPATH" >&2
  printf 'Create it from .env.example before running macOS setup.\n' >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENVPATH"

RED="${RED:-}"
BLUE="${BLUE:-}"
NC="${NC:-}"
OSX_PACKAGES="${OSX_PACKAGES:-}"

confirm() {
  local prompt="$1"
  local answer

  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi

  printf '%s [y/N] ' "$prompt"
  read -r answer || return 1
  [[ "$answer" == [Yy] || "$answer" == [Yy][Ee][Ss] ]]
}

install_homebrew() {
  printf 'Install %sbrew%s if it does not exist\n' "$BLUE" "$NC"

  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  printf 'No brew detected\n'
  xcode-select --install || true
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_packages() {
  local packages=()

  if [[ -z "$OSX_PACKAGES" ]]; then
    printf 'No macOS packages configured in OSX_PACKAGES.\n'
    return 0
  fi

  read -r -a packages <<<"$OSX_PACKAGES"
  printf 'Installing %spackages%s\n' "$RED" "$NC"
  printf '%s%s%s\n' "$BLUE" "$OSX_PACKAGES" "$NC"

  if confirm 'Install Homebrew packages?'; then
    brew install "${packages[@]}"
  fi
}

install_java() {
  printf 'Installing %sJava%s\n' "$RED" "$NC"

  if confirm 'Install Java cask?'; then
    brew install --cask java
  fi
}

main() {
  install_homebrew
  install_packages
  install_java
}

main "$@"
