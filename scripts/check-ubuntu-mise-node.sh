#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.tmp/ubuntu-mise-node-check"
LOG_FILE="$WORK_DIR/mise.log"
STATE_DIR="$WORK_DIR/state"

fail() {
  printf 'Ubuntu mise Node check failed: %s\n' "$*" >&2
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

assert_log_order() {
  local first="$1"
  local second="$2"
  local first_line
  local second_line

  first_line="$(grep -Fn "$first" "$LOG_FILE" | head -1 | cut -d: -f1 || true)"
  second_line="$(grep -Fn "$second" "$LOG_FILE" | head -1 | cut -d: -f1 || true)"

  [[ -n "$first_line" ]] || fail "missing first log entry: $first"
  [[ -n "$second_line" ]] || fail "missing second log entry: $second"
  (( first_line < second_line )) || fail "expected '$first' before '$second'"
}

reset_fixture() {
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR/bin" "$WORK_DIR/home/.local/bin" "$STATE_DIR"
  : >"$LOG_FILE"
}

write_mise_stub() {
  cat >"$WORK_DIR/bin/mise" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

printf 'mise %s\n' "$*" >>"$MISE_NODE_LOG"

case "$1" in
  use)
    exit 0
    ;;
  settings)
    exit 0
    ;;
  reshim)
    exit 0
    ;;
  install)
    if [[ "${MISE_NODE_MODE:-}" == "never-npm" ]]; then
      printf 'repair attempted\n' >>"$MISE_NODE_LOG"
      exit 0
    fi
    touch "$MISE_NODE_STATE/repaired"
    exit 0
    ;;
  exec)
    shift
    tool="$1"
    shift
    [[ "$1" == "--" ]] || exit 99
    shift
    command_name="$1"
    shift || true

    case "$command_name" in
      node)
        printf 'v24.15.0\n'
        exit 0
        ;;
      npm)
        if [[ "$1" == "--version" ]]; then
          if [[ "${MISE_NODE_MODE:-}" == "missing-npm-then-repair" && ! -e "$MISE_NODE_STATE/repaired" ]]; then
            printf 'mise ERROR "npm" could not exec process: No such file or directory\n' >&2
            exit 127
          fi
          if [[ "${MISE_NODE_MODE:-}" == "never-npm" ]]; then
            printf 'mise ERROR "npm" could not exec process: No such file or directory\n' >&2
            exit 127
          fi
          printf '10.9.0\n'
          exit 0
        fi
        if [[ "$1" == "install" && "$2" == "-g" ]]; then
          if [[ "$3" == "pnpm" ]]; then
            touch "$MISE_NODE_STATE/pnpm"
          fi
          exit 0
        fi
        exit 0
        ;;
      corepack)
        printf 'mise ERROR "corepack" could not exec process: No such file or directory\n' >&2
        exit 127
        ;;
      pnpm)
        [[ -e "$MISE_NODE_STATE/pnpm" ]] || exit 127
        printf '10.0.0\n'
        exit 0
        ;;
      *)
        exit 127
        ;;
    esac
    ;;
esac

exit 0
STUB
  chmod +x "$WORK_DIR/bin/mise"
}

reset_fixture
write_mise_stub

DOTFILES_TEST_ALLOW_LEGACY_BASH=1
HOME="$WORK_DIR/home"
PATH="$WORK_DIR/bin:$PATH"
MISE_NODE_LOG="$LOG_FILE"
MISE_NODE_STATE="$STATE_DIR"
MISE_NODE_MODE="missing-npm-then-repair"
export DOTFILES_TEST_ALLOW_LEGACY_BASH HOME PATH MISE_NODE_LOG MISE_NODE_STATE MISE_NODE_MODE

# shellcheck disable=SC1091
source "$ROOT_DIR/Ubuntu/setup-ubuntu.sh"

NODE_STRATEGY="mise"
NODE_PACKAGE_MANAGER="pnpm"
AGENT_TOOL_MODE="selected"
AGENT_TOOL_CSV="claude-code"

install_mise_and_node >/dev/null
install_node_package_manager >/dev/null
install_global_npm_packages "@anthropic-ai/claude-code" >/dev/null

assert_log_contains 'mise install --force node@lts'
assert_log_contains 'mise exec node@lts -- npm install -g pnpm'
assert_log_contains 'mise exec node@lts -- npm install -g @anthropic-ai/claude-code'
assert_log_order 'mise exec node@lts -- npm --version' 'mise install --force node@lts'
assert_log_order 'mise install --force node@lts' 'mise exec node@lts -- npm install -g @anthropic-ai/claude-code'

reset_fixture
write_mise_stub

HOME="$WORK_DIR/home"
PATH="$WORK_DIR/bin:$PATH"
MISE_NODE_LOG="$LOG_FILE"
MISE_NODE_STATE="$STATE_DIR"
MISE_NODE_MODE="never-npm"
export HOME PATH MISE_NODE_LOG MISE_NODE_STATE MISE_NODE_MODE

# shellcheck disable=SC1091
source "$ROOT_DIR/Ubuntu/setup-ubuntu.sh"

NODE_STRATEGY="mise"
AGENT_TOOL_MODE="selected"
AGENT_TOOL_CSV="claude-code"

if install_mise_and_node >"$WORK_DIR/out.txt" 2>&1; then
  cat "$WORK_DIR/out.txt" >&2
  fail 'install_mise_and_node succeeded even though npm never became available'
fi

if ! grep -Fq 'Node was installed through mise but npm is not available; cannot install npm-based agent CLIs.' "$WORK_DIR/out.txt"; then
  cat "$WORK_DIR/out.txt" >&2
  fail 'missing npm failure diagnostic'
fi

assert_log_not_contains 'mise exec node@lts -- npm install -g @anthropic-ai/claude-code'

printf 'Ubuntu mise Node check passed\n'
