#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/goznauk/dotfiles.git}"
REPO_REF="${DOTFILES_REPO_REF:-master}"
INSTALL_DIR="${DOTFILES_INSTALL_DIR:-$HOME/.local/share/goznauk-dotfiles}"

if ! command -v git >/dev/null 2>&1; then
  printf 'git is required before bootstrapping dotfiles.\n' >&2
  exit 1
fi

normalize_repo_url() {
  local url=${1%/}
  url=${url%.git}
  printf '%s\n' "$url"
}

ensure_managed_checkout() {
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    local current_url
    current_url="$(git -C "$INSTALL_DIR" remote get-url origin 2>/dev/null || true)"

    if [[ -z "$current_url" ]]; then
      printf 'Existing dotfiles checkout at %s has no origin remote.\n' "$INSTALL_DIR" >&2
      printf 'Move it aside or set DOTFILES_INSTALL_DIR to a new path before rerunning setup.\n' >&2
      exit 1
    fi

    if [[ "$(normalize_repo_url "$current_url")" != "$(normalize_repo_url "$REPO_URL")" ]]; then
      printf 'Existing dotfiles checkout at %s does not use the requested repository.\n' "$INSTALL_DIR" >&2
      printf 'Current origin: %s\n' "$current_url" >&2
      printf 'Requested origin: %s\n' "$REPO_URL" >&2
      printf 'Move it aside or set DOTFILES_INSTALL_DIR to a new path before rerunning setup.\n' >&2
      exit 1
    fi

    if [[ -n "$(git -C "$INSTALL_DIR" status --porcelain)" ]]; then
      printf 'Existing dotfiles checkout at %s has local changes.\n' "$INSTALL_DIR" >&2
      printf 'Commit, stash, or move those changes before rerunning setup.\n' >&2
      exit 1
    fi

    printf 'Reusing managed dotfiles checkout at %s\n' "$INSTALL_DIR" >&2
  elif [[ -e "$INSTALL_DIR" ]]; then
    printf 'Install directory %s exists but is not a git checkout.\n' "$INSTALL_DIR" >&2
    printf 'Move it aside or set DOTFILES_INSTALL_DIR to a new path before rerunning setup.\n' >&2
    exit 1
  else
    mkdir -p "$(dirname "$INSTALL_DIR")"
    printf 'Cloning dotfiles from %s into %s\n' "$REPO_URL" "$INSTALL_DIR" >&2
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi
}

checkout_requested_ref() {
  printf 'Fetching dotfiles updates from origin\n' >&2
  git -C "$INSTALL_DIR" fetch --prune --tags origin

  if git -C "$INSTALL_DIR" show-ref --verify --quiet "refs/remotes/origin/$REPO_REF"; then
    printf 'Aligning managed checkout to origin/%s\n' "$REPO_REF" >&2
    git -C "$INSTALL_DIR" checkout -B "$REPO_REF" "origin/$REPO_REF"
  else
    printf 'Checking out dotfiles ref %s\n' "$REPO_REF" >&2
    git -C "$INSTALL_DIR" checkout --detach "$REPO_REF"
  fi

  printf 'Dotfiles checkout is at %s\n' "$(git -C "$INSTALL_DIR" rev-parse --short HEAD)" >&2
}

ensure_managed_checkout
checkout_requested_ref

cd "$INSTALL_DIR"
exec ./setup.sh "$@"
