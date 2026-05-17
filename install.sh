#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/goznauk/dotfiles.git}"
REPO_REF="${DOTFILES_REPO_REF:-main}"
INSTALL_DIR="${DOTFILES_INSTALL_DIR:-$HOME/.local/share/goznauk-dotfiles}"

if ! command -v git >/dev/null 2>&1; then
  printf 'git is required before bootstrapping dotfiles.\n' >&2
  exit 1
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" fetch --prune origin
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

git -C "$INSTALL_DIR" checkout "$REPO_REF"
git -C "$INSTALL_DIR" pull --ff-only origin "$REPO_REF"

exec "$INSTALL_DIR/setup.sh" "$@"
