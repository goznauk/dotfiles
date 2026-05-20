#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.tmp/ubuntu-zsh-framework-check"

fail() {
  printf 'Ubuntu zsh framework check failed: %s\n' "$*" >&2
  exit 1
}

run_git() {
  git "$@" >/dev/null 2>&1
}

commit_all() {
  local repo=$1
  local message=$2

  git -C "$repo" add .
  git -C "$repo" \
    -c user.name='Dotfiles Check' \
    -c user.email='dotfiles-check@example.invalid' \
    commit -m "$message" >/dev/null
}

create_origin() {
  local origin=$1
  local source=$2
  local fixture=$3

  run_git init --bare --initial-branch=master "$origin"
  run_git init -b master "$source"

  case "$fixture" in
    oh-my-zsh)
      cat >"$source/oh-my-zsh.sh" <<'OMZ'
for plugin in "${plugins[@]}"; do
  case "$plugin" in
    git|common-aliases|ssh-agent|dotenv|docker|docker-compose)
      ;;
    *)
      plugin_file="${ZSH_CUSTOM:-$ZSH/custom}/plugins/$plugin/$plugin.plugin.zsh"
      if [[ ! -r "$plugin_file" ]]; then
        print -u2 "[oh-my-zsh] plugin '$plugin' not found"
      fi
      ;;
  esac
done
if [[ -n "${ZSH_THEME:-}" ]]; then
  theme_file="${ZSH_CUSTOM:-$ZSH/custom}/themes/${ZSH_THEME}.zsh-theme"
  [[ -r "$theme_file" ]] && source "$theme_file"
fi
OMZ
      ;;
    powerlevel10k)
      cat >"$source/powerlevel10k.zsh-theme" <<'P10K'
p10k() { :; }
P10K
      ;;
    zsh-syntax-highlighting)
      printf '# zsh-syntax-highlighting fixture\n' >"$source/zsh-syntax-highlighting.zsh"
      ;;
    zsh-autosuggestions)
      printf '# zsh-autosuggestions fixture\n' >"$source/zsh-autosuggestions.zsh"
      ;;
    zsh-completions)
      mkdir -p "$source/src"
      printf '#compdef fixture\n' >"$source/src/_fixture"
      ;;
    other)
      printf 'other fixture\n' >"$source/README.md"
      ;;
    *)
      fail "unknown fixture $fixture"
      ;;
  esac

  commit_all "$source" "fixture $fixture"
  run_git -C "$source" remote add origin "$origin"
  run_git -C "$source" push -u origin master
}

assert_glob_exists() {
  local pattern=$1
  local matches=()

  shopt -s nullglob
  matches=($pattern)
  shopt -u nullglob
  [[ "${#matches[@]}" -gt 0 ]] || fail "expected path matching $pattern"
}

assert_contains() {
  local file=$1
  local expected=$2

  if ! grep -Fq "$expected" "$file"; then
    printf '%s\n' "--- $file ---" >&2
    sed -n '1,120p' "$file" >&2
    fail "expected '$expected' in $file"
  fi
}

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
trap 'rm -rf "$WORK_DIR"' EXIT

core_origin="$WORK_DIR/oh-my-zsh.git"
core_source="$WORK_DIR/oh-my-zsh-source"
p10k_origin="$WORK_DIR/powerlevel10k.git"
p10k_source="$WORK_DIR/powerlevel10k-source"
syntax_origin="$WORK_DIR/zsh-syntax-highlighting.git"
syntax_source="$WORK_DIR/zsh-syntax-highlighting-source"
autosuggestions_origin="$WORK_DIR/zsh-autosuggestions.git"
autosuggestions_source="$WORK_DIR/zsh-autosuggestions-source"
completions_origin="$WORK_DIR/zsh-completions.git"
completions_source="$WORK_DIR/zsh-completions-source"
other_origin="$WORK_DIR/other.git"
other_source="$WORK_DIR/other-source"

create_origin "$core_origin" "$core_source" oh-my-zsh
create_origin "$p10k_origin" "$p10k_source" powerlevel10k
create_origin "$syntax_origin" "$syntax_source" zsh-syntax-highlighting
create_origin "$autosuggestions_origin" "$autosuggestions_source" zsh-autosuggestions
create_origin "$completions_origin" "$completions_source" zsh-completions
create_origin "$other_origin" "$other_source" other

DOTFILES_TEST_ALLOW_LEGACY_BASH=1
HOME="$WORK_DIR/home"
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
SHELL="/bin/bash"
DOTFILES_OH_MY_ZSH_URL="$core_origin"
DOTFILES_POWERLEVEL10K_URL="$p10k_origin"
DOTFILES_ZSH_SYNTAX_HIGHLIGHTING_URL="$syntax_origin"
DOTFILES_ZSH_AUTOSUGGESTIONS_URL="$autosuggestions_origin"
DOTFILES_ZSH_COMPLETIONS_URL="$completions_origin"
export HOME PATH SHELL DOTFILES_TEST_ALLOW_LEGACY_BASH
export DOTFILES_OH_MY_ZSH_URL DOTFILES_POWERLEVEL10K_URL
export DOTFILES_ZSH_SYNTAX_HIGHLIGHTING_URL DOTFILES_ZSH_AUTOSUGGESTIONS_URL DOTFILES_ZSH_COMPLETIONS_URL

# shellcheck disable=SC1091
source "$ROOT_DIR/Ubuntu/setup-ubuntu.sh"

YES=1
POWERLEVEL10K=1

HOME="$WORK_DIR/missing-home"
mkdir -p "$HOME"
ensure_oh_my_zsh
[[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]] || fail 'missing Oh My Zsh core was not cloned'

HOME="$WORK_DIR/broken-home"
mkdir -p "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
printf 'old custom content\n' >"$HOME/.oh-my-zsh/custom/themes/powerlevel10k/old.txt"
ensure_oh_my_zsh
[[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]] || fail 'broken Oh My Zsh core was not repaired'
assert_glob_exists "$HOME/.oh-my-zsh.backup."*

HOME="$WORK_DIR/broken-git-home"
mkdir -p "$HOME/.oh-my-zsh/.git"
ensure_oh_my_zsh
[[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]] || fail 'broken Oh My Zsh git checkout was not repaired'
assert_glob_exists "$HOME/.oh-my-zsh.backup."*

HOME="$WORK_DIR/mismatched-origin-home"
mkdir -p "$HOME"
git clone --depth=1 "$other_origin" "$HOME/.oh-my-zsh" >/dev/null
ensure_oh_my_zsh
current_origin="$(git -C "$HOME/.oh-my-zsh" remote get-url origin)"
[[ "${current_origin%.git}" == "${core_origin%.git}" ]] || fail 'mismatched Oh My Zsh origin was not repaired'
assert_glob_exists "$HOME/.oh-my-zsh.backup."*

HOME="$WORK_DIR/install-home"
mkdir -p "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
printf 'stale theme\n' >"$HOME/.oh-my-zsh/custom/themes/powerlevel10k/old.txt"
install_shell >/dev/null
[[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]] || fail 'install_shell did not ensure Oh My Zsh core'
[[ -f "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]] || fail 'install_shell did not ensure Powerlevel10k after core repair'
[[ -f "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] || fail 'install_shell did not ensure zsh-syntax-highlighting'
[[ -f "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] || fail 'install_shell did not ensure zsh-autosuggestions'
[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src" ]] || fail 'install_shell did not ensure zsh-completions'
install_dotfiles >/dev/null
verify_zsh_setup >/dev/null
if command -v zsh >/dev/null 2>&1; then
  output="$(HOME="$HOME" ZSH="$HOME/.oh-my-zsh" ZSH_CUSTOM="$HOME/.oh-my-zsh/custom" zsh -i -c 'source ~/.zshrc >/dev/null; type p10k >/dev/null' 2>&1)"
  if grep -Fq "[oh-my-zsh] plugin" <<<"$output"; then
    printf '%s\n' "$output" >&2
    fail 'managed zsh plugins produced Oh My Zsh plugin-not-found warnings'
  fi
fi

HOME="$WORK_DIR/verify-missing-home"
mkdir -p "$HOME"
if verify_zsh_setup 2>"$WORK_DIR/verify-missing.err"; then
  fail 'verification passed without Oh My Zsh core'
fi
assert_contains "$WORK_DIR/verify-missing.err" 'Oh My Zsh core is missing'

HOME="$WORK_DIR/verify-no-p10k-home"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src"
printf '# core\n' >"$HOME/.oh-my-zsh/oh-my-zsh.sh"
printf '# syntax\n' >"$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
printf '# autosuggestions\n' >"$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
POWERLEVEL10K=0
verify_zsh_setup >/dev/null
POWERLEVEL10K=1

if command -v zsh >/dev/null 2>&1; then
  HOME="$WORK_DIR/verify-broken-p10k-home"
  mkdir -p "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src"
  cat >"$HOME/.oh-my-zsh/oh-my-zsh.sh" <<'OMZ'
if [[ -n "${ZSH_THEME:-}" ]]; then
  theme_file="${ZSH_CUSTOM:-$ZSH/custom}/themes/${ZSH_THEME}.zsh-theme"
  [[ -r "$theme_file" ]] && source "$theme_file"
fi
OMZ
  printf '# p10k intentionally not defined\n' >"$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
  printf '# syntax\n' >"$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  printf '# autosuggestions\n' >"$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ln -s "$ROOT_DIR/common/.zshrc" "$HOME/.zshrc"
  if verify_zsh_setup 2>"$WORK_DIR/verify-broken-p10k.err"; then
    fail 'verification passed when Powerlevel10k was not loadable'
  fi
  assert_contains "$WORK_DIR/verify-broken-p10k.err" 'Powerlevel10k did not load'

  HOME="$WORK_DIR/warn-home"
  mkdir -p "$HOME"
  output="$(env -u ZSH HOME="$HOME" zsh -i -c "source '$ROOT_DIR/common/.zshrc'" 2>&1 || true)"
  if ! grep -Fq 'WARN: Oh My Zsh not found' <<<"$output"; then
    printf '%s\n' "$output" >&2
    fail '.zshrc did not warn when Oh My Zsh core was missing'
  fi
fi

printf 'Ubuntu zsh framework check passed\n'
