#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.tmp/ubuntu-shell-noninteractive-check"

fail() {
  printf 'Ubuntu shell noninteractive check failed: %s\n' "$*" >&2
  exit 1
}

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/bin" "$WORK_DIR/home/.oh-my-zsh/custom/themes" "$WORK_DIR/home/.oh-my-zsh/custom/plugins"
trap 'rm -rf "$WORK_DIR"' EXIT

cat >"$WORK_DIR/bin/zsh" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$WORK_DIR/bin/zsh"

cat >"$WORK_DIR/bin/chsh" <<'STUB'
#!/usr/bin/env bash
printf 'chsh should not be called in --yes shell setup\n' >&2
exit 42
STUB
chmod +x "$WORK_DIR/bin/chsh"

cat >"$WORK_DIR/bin/git" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == "clone" ]]; then
  dest="${@: -1}"
  mkdir -p "$dest/.git"
  case "$dest" in
    */.oh-my-zsh)
      printf '# oh-my-zsh fixture\n' >"$dest/oh-my-zsh.sh"
      ;;
    */themes/powerlevel10k)
      printf 'p10k() { :; }\n' >"$dest/powerlevel10k.zsh-theme"
      ;;
    */plugins/zsh-syntax-highlighting)
      printf '# syntax fixture\n' >"$dest/zsh-syntax-highlighting.zsh"
      ;;
    */plugins/zsh-autosuggestions)
      printf '# autosuggestions fixture\n' >"$dest/zsh-autosuggestions.zsh"
      ;;
    */plugins/zsh-completions)
      mkdir -p "$dest/src"
      ;;
  esac
  exit 0
fi
exit 0
STUB
chmod +x "$WORK_DIR/bin/git"

cat >"$WORK_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$WORK_DIR/bin/curl"

DOTFILES_TEST_ALLOW_LEGACY_BASH=1
HOME="$WORK_DIR/home"
PATH="$WORK_DIR/bin:$PATH"
SHELL="/bin/bash"
ZSH_CUSTOM="$WORK_DIR/home/.oh-my-zsh/custom"
export HOME PATH SHELL ZSH_CUSTOM DOTFILES_TEST_ALLOW_LEGACY_BASH

# shellcheck disable=SC1091
source "$ROOT_DIR/Ubuntu/setup-ubuntu.sh"

YES=1
POWERLEVEL10K=1

output="$(install_shell 2>&1)" || {
  printf '%s\n' "$output" >&2
  fail 'install_shell failed'
}

if grep -Fq 'chsh should not be called' <<<"$output"; then
  printf '%s\n' "$output" >&2
  fail 'chsh was called in noninteractive shell setup'
fi

if ! grep -Fq 'Skipping login shell change in --yes mode' <<<"$output"; then
  printf '%s\n' "$output" >&2
  fail 'missing noninteractive chsh skip warning'
fi

printf 'Ubuntu shell noninteractive check passed\n'
