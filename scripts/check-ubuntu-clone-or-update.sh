#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.tmp/ubuntu-clone-or-update-check"

fail() {
  printf 'Ubuntu clone_or_update check failed: %s\n' "$*" >&2
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
  local marker=$3

  run_git init --bare --initial-branch=master "$origin"
  run_git init -b master "$source"
  printf 'fixture %s\n' "$marker" >"$source/README.md"
  commit_all "$source" "fixture $marker"
  run_git -C "$source" remote add origin "$origin"
  run_git -C "$source" push -u origin master
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

assert_glob_exists() {
  local pattern=$1
  local matches=()

  shopt -s nullglob
  matches=($pattern)
  shopt -u nullglob
  [[ "${#matches[@]}" -gt 0 ]] || fail "expected path matching $pattern"
}

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
trap 'rm -rf "$WORK_DIR"' EXIT

DOTFILES_TEST_ALLOW_LEGACY_BASH=1
# shellcheck disable=SC1091
source "$ROOT_DIR/Ubuntu/setup-ubuntu.sh"

origin_one="$WORK_DIR/origin-one.git"
source_one="$WORK_DIR/source-one"
dest="$WORK_DIR/plugin"
err_file="$WORK_DIR/err.txt"

create_origin "$origin_one" "$source_one" "one"
clone_or_update "$origin_one" "$dest" 2>"$err_file"
[[ -d "$dest/.git" ]] || fail 'new plugin checkout was not cloned'

printf 'fixture two\n' >"$source_one/README.md"
commit_all "$source_one" "fixture two"
run_git -C "$source_one" push origin master
clone_or_update "$origin_one" "$dest" 2>"$err_file"

remote_head="$(git --git-dir="$origin_one" rev-parse refs/heads/master)"
local_head="$(git -C "$dest" rev-parse HEAD)"
[[ "$local_head" == "$remote_head" ]] || fail 'existing plugin checkout was not updated'

non_git_dest="$WORK_DIR/non-git-plugin"
mkdir -p "$non_git_dest"
printf 'local file\n' >"$non_git_dest/file.txt"
clone_or_update "$origin_one" "$non_git_dest" 2>"$err_file"
assert_contains "$err_file" 'already exists but is not a git checkout'
assert_contains "$non_git_dest/file.txt" 'local file'

broken_dest="$WORK_DIR/broken-plugin"
mkdir -p "$broken_dest/.git"
clone_or_update "$origin_one" "$broken_dest" 2>"$err_file"
assert_contains "$err_file" 'not a valid standalone git checkout'

origin_two="$WORK_DIR/origin-two.git"
source_two="$WORK_DIR/source-two"
create_origin "$origin_two" "$source_two" "other"
clone_or_update "$origin_two" "$dest" 2>"$err_file"
assert_contains "$err_file" 'origin does not match'

YES=1

managed_non_git_dest="$WORK_DIR/managed-non-git-plugin"
mkdir -p "$managed_non_git_dest"
printf 'local file\n' >"$managed_non_git_dest/file.txt"
clone_or_update "$origin_one" "$managed_non_git_dest" 2>"$err_file"
[[ -d "$managed_non_git_dest/.git" ]] || fail 'managed non-git plugin was not recloned'
assert_glob_exists "$managed_non_git_dest.backup."*

managed_broken_dest="$WORK_DIR/managed-broken-plugin"
mkdir -p "$managed_broken_dest/.git"
clone_or_update "$origin_one" "$managed_broken_dest" 2>"$err_file"
[[ -d "$managed_broken_dest/.git" ]] || fail 'managed broken plugin was not recloned'
assert_glob_exists "$managed_broken_dest.backup."*

clone_or_update "$origin_two" "$dest" 2>"$err_file"
current_url="$(git -C "$dest" remote get-url origin)"
[[ "${current_url%.git}" == "${origin_two%.git}" ]] || fail 'managed mismatched plugin origin was not recloned'
assert_glob_exists "$dest.backup."*

printf 'Ubuntu clone_or_update check passed\n'
