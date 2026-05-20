#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.tmp/ubuntu-rustup-repair-check"
LOG_FILE="$WORK_DIR/rust.log"
STATE_DIR="$WORK_DIR/state"

fail() {
  printf 'Ubuntu rustup repair check failed: %s\n' "$*" >&2
  exit 1
}

assert_log_contains() {
  local expected="$1"

  if ! grep -Fq "$expected" "$LOG_FILE"; then
    printf '%s\n' "--- $LOG_FILE ---" >&2
    sed -n '1,200p' "$LOG_FILE" >&2
    fail "expected log entry: $expected"
  fi
}

assert_log_not_contains() {
  local unexpected="$1"

  if grep -Fq "$unexpected" "$LOG_FILE"; then
    printf '%s\n' "--- $LOG_FILE ---" >&2
    sed -n '1,200p' "$LOG_FILE" >&2
    fail "unexpected log entry: $unexpected"
  fi
}

reset_fixture() {
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR/bin" "$WORK_DIR/home/.cargo/bin" "$STATE_DIR" "$WORK_DIR/rustup/toolchains/stable-x86_64-unknown-linux-gnu"
  : >"$LOG_FILE"
}

write_rust_stubs() {
  cat >"$WORK_DIR/bin/rustup" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

printf 'rustup %s\n' "$*" >>"$RUST_REPAIR_LOG"

case "$1" in
  --version)
    printf 'rustup 1.28.0\n'
    exit 0
    ;;
  toolchain)
    case "$2" in
      list)
        printf 'stable-x86_64-unknown-linux-gnu (default)\n'
        exit 0
        ;;
      uninstall)
        if [[ "${RUST_REPAIR_MODE:-}" == "corrupt-uninstall-fails" ]]; then
          printf 'error: Missing manifest in toolchain stable-x86_64-unknown-linux-gnu\n' >&2
          exit 1
        fi
        touch "$RUST_REPAIR_STATE/uninstalled"
        rm -rf "$RUSTUP_HOME"/toolchains/stable-*
        exit 0
        ;;
      install)
        touch "$RUST_REPAIR_STATE/repaired"
        mkdir -p "$RUSTUP_HOME/toolchains/stable-x86_64-unknown-linux-gnu"
        exit 0
        ;;
    esac
    ;;
  default)
    exit 0
    ;;
  component)
    [[ -e "$RUST_REPAIR_STATE/repaired" || "${RUST_REPAIR_MODE:-}" == "healthy" ]] || exit 1
    exit 0
    ;;
esac

exit 0
STUB

  cat >"$WORK_DIR/bin/rustc" <<'STUB'
#!/usr/bin/env bash
printf 'rustc %s\n' "$*" >>"$RUST_REPAIR_LOG"
if [[ "${RUST_REPAIR_MODE:-}" == "healthy" || -e "$RUST_REPAIR_STATE/repaired" ]]; then
  printf 'rustc 1.90.0\n'
  exit 0
fi
printf 'error: Missing manifest in toolchain stable-x86_64-unknown-linux-gnu\n' >&2
exit 1
STUB

  cat >"$WORK_DIR/bin/cargo" <<'STUB'
#!/usr/bin/env bash
printf 'cargo %s\n' "$*" >>"$RUST_REPAIR_LOG"
if [[ "${RUST_REPAIR_MODE:-}" == "healthy" || -e "$RUST_REPAIR_STATE/repaired" ]]; then
  printf 'cargo 1.90.0\n'
  exit 0
fi
printf 'error: error reading rustc version\n' >&2
exit 1
STUB

  chmod +x "$WORK_DIR/bin/rustup" "$WORK_DIR/bin/rustc" "$WORK_DIR/bin/cargo"
}

reset_fixture
write_rust_stubs

DOTFILES_TEST_ALLOW_LEGACY_BASH=1
HOME="$WORK_DIR/home"
PATH="$WORK_DIR/bin:$PATH"
RUSTUP_HOME="$WORK_DIR/rustup"
CARGO_HOME="$WORK_DIR/cargo"
RUST_REPAIR_LOG="$LOG_FILE"
RUST_REPAIR_STATE="$STATE_DIR"
RUST_REPAIR_MODE="healthy"
export DOTFILES_TEST_ALLOW_LEGACY_BASH HOME PATH RUSTUP_HOME CARGO_HOME RUST_REPAIR_LOG RUST_REPAIR_STATE RUST_REPAIR_MODE

# shellcheck disable=SC1091
source "$ROOT_DIR/Ubuntu/setup-ubuntu.sh"

install_rust >/dev/null
assert_log_not_contains 'rustup toolchain uninstall stable'
assert_log_contains 'rustup component add rustfmt clippy'

reset_fixture
write_rust_stubs
HOME="$WORK_DIR/home"
PATH="$WORK_DIR/bin:$PATH"
RUSTUP_HOME="$WORK_DIR/rustup"
CARGO_HOME="$WORK_DIR/cargo"
RUST_REPAIR_LOG="$LOG_FILE"
RUST_REPAIR_STATE="$STATE_DIR"
RUST_REPAIR_MODE="corrupt-uninstall-fails"
export HOME PATH RUSTUP_HOME CARGO_HOME RUST_REPAIR_LOG RUST_REPAIR_STATE RUST_REPAIR_MODE

# shellcheck disable=SC1091
source "$ROOT_DIR/Ubuntu/setup-ubuntu.sh"

install_rust >/dev/null
assert_log_contains 'rustup toolchain uninstall stable'
assert_log_contains 'rustup toolchain install stable'
assert_log_contains 'rustup default stable'
assert_log_contains 'rustup component add rustfmt clippy'
[[ -e "$STATE_DIR/repaired" ]] || fail 'corrupt stable toolchain was not reinstalled'
[[ -d "$RUSTUP_HOME/toolchains/stable-x86_64-unknown-linux-gnu" ]] || fail 'stable toolchain directory was not recreated'

printf 'Ubuntu rustup repair check passed\n'
