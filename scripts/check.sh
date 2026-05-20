#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

log 'Checking package catalog and chooser build'
npm --prefix "$ROOT_DIR/chooser" run check

log 'Checking shell syntax'
bash -n \
  "$ROOT_DIR/setup.sh" \
  "$ROOT_DIR/install.sh" \
  "$ROOT_DIR/Ubuntu/setup-ubuntu.sh" \
  "$ROOT_DIR/MacOS/setup-mac.sh"

log 'Checking install bootstrap behavior'
bash "$ROOT_DIR/scripts/check-install-bootstrap.sh"
bash "$ROOT_DIR/scripts/check-ubuntu-clone-or-update.sh"
bash "$ROOT_DIR/scripts/check-ubuntu-shell-noninteractive.sh"
bash "$ROOT_DIR/scripts/check-ubuntu-zsh-framework.sh"
bash "$ROOT_DIR/scripts/check-ubuntu-mise-node.sh"
bash "$ROOT_DIR/scripts/check-ubuntu-rustup-repair.sh"

node "$ROOT_DIR/scripts/check-bash-nameref.mjs" "$ROOT_DIR/Ubuntu/setup-ubuntu.sh"
node "$ROOT_DIR/scripts/check-ubuntu-apt-setup.mjs"
node "$ROOT_DIR/scripts/check-zsh-tmux-helpers.mjs"

if command -v zsh >/dev/null 2>&1; then
  zsh -n "$ROOT_DIR/common/.zshrc"
else
  warn 'zsh not found; skipping .zshrc syntax check.'
fi

if command -v vim >/dev/null 2>&1; then
  DOTFILES_SKIP_NETWORK=1 vim -Nu "$ROOT_DIR/common/.vimrc" -n -es -c qall
else
  warn 'vim not found; skipping .vimrc load check.'
fi

if command -v tmux >/dev/null 2>&1; then
  tmux_socket="dotfiles-check-$$"
  tmux -L "$tmux_socket" -f "$ROOT_DIR/common/.tmux.conf" new-session -d -s dotfiles-check "sleep 60" 2>/dev/null || true
  if tmux -L "$tmux_socket" has-session -t dotfiles-check 2>/dev/null; then
    if ! tmux -L "$tmux_socket" source-file "$ROOT_DIR/common/.tmux.conf"; then
      tmux -L "$tmux_socket" kill-server
      exit 1
    fi
    tmux -L "$tmux_socket" kill-server
  else
    warn 'tmux server could not start; skipping .tmux.conf load check.'
  fi
else
  warn 'tmux not found; skipping .tmux.conf load check.'
fi

log 'Checking JSON files'
node --input-type=module -e '
  import { readFileSync } from "node:fs";
  for (const path of process.argv.slice(1)) {
    JSON.parse(readFileSync(path, "utf8"));
  }
' \
  "$ROOT_DIR/packages/catalog.json" \
  "$ROOT_DIR/MacOS/config_files/Karabiner_KorEng.json"

log 'Checking ASCII text policy'
if LC_ALL=C rg --hidden -n -g '!node_modules' -g '!dist' '[^ -~	]' \
  "$ROOT_DIR/chooser" \
  "$ROOT_DIR/packages" \
  "$ROOT_DIR/Ubuntu" \
  "$ROOT_DIR/common" \
  "$ROOT_DIR/scripts" \
  "$ROOT_DIR/docs" \
  "$ROOT_DIR/fonts/README.md" \
  "$ROOT_DIR/fonts/LICENSE-APACHE-2.0.txt" \
  "$ROOT_DIR/.github/workflows/pages.yml" \
  "$ROOT_DIR/MacOS/README.md" \
  "$ROOT_DIR/MacOS/setup-mac.sh" \
  "$ROOT_DIR/MacOS/config_files/Karabiner_KorEng.json" \
  "$ROOT_DIR/README.md" \
  "$ROOT_DIR/setup.sh" \
  "$ROOT_DIR/install.sh" \
  "$ROOT_DIR/.env.example" \
  "$ROOT_DIR/.editorconfig" \
  "$ROOT_DIR/.gitignore"; then
  printf 'Non-ASCII text found in checked source files.\n' >&2
  exit 1
fi

log 'Checking Git diff whitespace'
git -C "$ROOT_DIR" diff --check

log 'Repository checks passed'
