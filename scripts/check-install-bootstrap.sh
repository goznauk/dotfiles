#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.tmp/install-bootstrap-check"

fail() {
  printf 'install bootstrap check failed: %s\n' "$*" >&2
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

write_fixture_repo() {
  local repo=$1
  local marker=$2

  cat >"$repo/setup.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf 'fixture setup %s\n' "$marker"
printf 'fixture cwd %s\n' "\$PWD"
EOF
  chmod +x "$repo/setup.sh"
  printf 'fixture %s\n' "$marker" >"$repo/README.md"
}

create_origin() {
  local origin=$1
  local source=$2
  local marker=$3

  run_git init --bare --initial-branch=master "$origin"
  run_git init -b master "$source"
  write_fixture_repo "$source" "$marker"
  commit_all "$source" "fixture $marker"
  run_git -C "$source" remote add origin "$origin"
  run_git -C "$source" push -u origin master
}

run_installer() {
  local repo_url=$1
  local install_dir=$2
  local out_file=$3
  local err_file=$4

  DOTFILES_REPO_URL="$repo_url" \
    DOTFILES_INSTALL_DIR="$install_dir" \
    DOTFILES_REPO_REF=master \
    bash "$ROOT_DIR/install.sh" --help >"$out_file" 2>"$err_file"
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

origin_one="$WORK_DIR/origin-one.git"
source_one="$WORK_DIR/source-one"
install_dir="$WORK_DIR/install"
out_file="$WORK_DIR/out.txt"
err_file="$WORK_DIR/err.txt"

create_origin "$origin_one" "$source_one" "one"
run_installer "$origin_one" "$install_dir" "$out_file" "$err_file"
assert_contains "$out_file" "fixture cwd $install_dir"

first_head="$(git -C "$install_dir" rev-parse HEAD)"

printf 'fixture two\n' >"$source_one/README.md"
commit_all "$source_one" "fixture two"
run_git -C "$source_one" push origin master
run_installer "$origin_one" "$install_dir" "$out_file" "$err_file"

run_git -C "$source_one" reset --hard "$first_head"
printf 'fixture forced\n' >"$source_one/README.md"
commit_all "$source_one" "fixture forced"
run_git -C "$source_one" push --force-with-lease origin master

run_installer "$origin_one" "$install_dir" "$out_file" "$err_file"

remote_head="$(git --git-dir="$origin_one" rev-parse refs/heads/master)"
local_head="$(git -C "$install_dir" rev-parse HEAD)"
[[ "$local_head" == "$remote_head" ]] || fail 'clean diverged checkout was not realigned to origin/master'
assert_contains "$err_file" 'Aligning managed checkout to origin/master'

printf 'local change\n' >>"$install_dir/README.md"
if run_installer "$origin_one" "$install_dir" "$out_file" "$err_file"; then
  fail 'dirty checkout update succeeded unexpectedly'
fi
assert_contains "$err_file" 'has local changes'
assert_contains "$install_dir/README.md" 'local change'

origin_two="$WORK_DIR/origin-two.git"
source_two="$WORK_DIR/source-two"
create_origin "$origin_two" "$source_two" "other"

run_git -C "$install_dir" checkout -- README.md
if run_installer "$origin_two" "$install_dir" "$out_file" "$err_file"; then
  fail 'mismatched remote update succeeded unexpectedly'
fi
assert_contains "$err_file" 'does not use the requested repository'

non_git_dir="$WORK_DIR/non-git-install"
mkdir -p "$non_git_dir"
printf 'not a git repo\n' >"$non_git_dir/file.txt"
if run_installer "$origin_one" "$non_git_dir" "$out_file" "$err_file"; then
  fail 'non-git install directory succeeded unexpectedly'
fi
assert_contains "$err_file" 'exists but is not a git checkout'

printf 'install bootstrap check passed\n'
