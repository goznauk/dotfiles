#!/usr/bin/env bash
set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  printf 'Ubuntu setup requires Bash 4 or newer. Ubuntu ships a supported Bash version by default.\n' >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/common"
PACKAGE_DIR="$ROOT_DIR/Ubuntu/packages"

YES=0
SKIP_APT=0
SKIP_DOTFILES=0
SKIP_SHELL=0
SKIP_TOOLS=0
WITH_TPM=0
PROXMOX_GUEST_AGENT=0
DRY_RUN=0
POWERLEVEL10K=1
CREATE_ADMIN_USER=0
TMUX_PREFIX=""
SAVE_SETUP_PREFERENCES=0
LOAD_SETUP_PREFERENCES=0
SETUP_PREFERENCES_FILE="${DOTFILES_SETUP_PREFERENCES_FILE:-$HOME/.config/dotfiles/setup.env}"
APT_PACKAGE_MODE="default"
APT_PACKAGE_CSV=""
OPTIONAL_PACKAGE_MODE="all"
OPTIONAL_PACKAGE_CSV=""
EXTRA_PACKAGE_CSV=""
DOCKER_STRATEGY="official"
NODE_STRATEGY="mise"
NODE_PACKAGE_MANAGER="pnpm"
PYTHON_STRATEGY="system-uv"
JAVA_STRATEGY="none"
DEVELOPER_TOOL_MODE="default"
DEVELOPER_TOOL_CSV="rust,go,bun,deno,gh"
AGENT_TOOL_MODE="default"
AGENT_TOOL_CSV="claude-code,openai-codex"
ADMIN_USER_MODE="current"
ADMIN_USER_NAME=""
TARGET_VERSION=""

is_valid_admin_user_name() {
  local user_name="$1"

  [[ "$user_name" =~ ^[a-z][a-z0-9_-]{0,31}$ && "$user_name" != "root" ]]
}

load_setup_preferences() {
  local line
  local key
  local value

  [[ -r "$SETUP_PREFERENCES_FILE" ]] || return 0

  while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
    [[ -z "${key:-}" || "$key" =~ ^[[:space:]]*# ]] && continue
    case "$key" in
      DOTFILES_ADMIN_USER_NAME)
        if is_valid_admin_user_name "$value"; then
          ADMIN_USER_MODE="selected"
          ADMIN_USER_NAME="$value"
        else
          printf 'WARN: Ignoring invalid saved admin user: %s\n' "$value" >&2
        fi
        ;;
      DOTFILES_TARGET_VERSION)
        if [[ "$value" =~ ^[0-9][0-9.]*$ ]]; then
          TARGET_VERSION="$value"
        else
          printf 'WARN: Ignoring invalid saved target version: %s\n' "$value" >&2
        fi
        ;;
      DOTFILES_TMUX_PREFIX)
        case "$value" in
          ctrl-a|ctrl-b)
            TMUX_PREFIX="$value"
            ;;
          *)
            printf 'WARN: Ignoring invalid saved tmux prefix: %s\n' "$value" >&2
            ;;
        esac
        ;;
      DOTFILES_PROXMOX_GUEST_AGENT)
        case "$value" in
          0|1)
            PROXMOX_GUEST_AGENT="$value"
            ;;
        esac
        ;;
    esac
  done <"$SETUP_PREFERENCES_FILE"
}

save_setup_preferences() {
  local preferences_dir
  local temp_file
  local saved_tmux_prefix="${TMUX_PREFIX:-ctrl-a}"

  preferences_dir="$(dirname "$SETUP_PREFERENCES_FILE")"
  mkdir -p "$preferences_dir"
  chmod 700 "$preferences_dir"

  temp_file="${SETUP_PREFERENCES_FILE}.tmp.$$"
  : >"$temp_file"
  chmod 600 "$temp_file"
  printf '# Non-secret dotfiles setup preferences.\n' >>"$temp_file"
  if [[ -n "$TARGET_VERSION" ]]; then
    printf 'DOTFILES_TARGET_VERSION=%s\n' "$TARGET_VERSION" >>"$temp_file"
  fi
  if [[ -n "$ADMIN_USER_NAME" && "$ADMIN_USER_MODE" == "selected" ]]; then
    printf 'DOTFILES_ADMIN_USER_NAME=%s\n' "$ADMIN_USER_NAME" >>"$temp_file"
  fi
  printf 'DOTFILES_TMUX_PREFIX=%s\n' "$saved_tmux_prefix" >>"$temp_file"
  printf 'DOTFILES_PROXMOX_GUEST_AGENT=%s\n' "$PROXMOX_GUEST_AGENT" >>"$temp_file"
  mv "$temp_file" "$SETUP_PREFERENCES_FILE"
  chmod 600 "$SETUP_PREFERENCES_FILE"
}

usage() {
  cat <<'USAGE'
Usage:
  ./Ubuntu/setup-ubuntu.sh [options]

Options:
  -y, --yes        Run without confirmation prompts
  --skip-apt       Skip apt packages
  --skip-dotfiles  Skip dotfile links
  --skip-shell     Skip zsh and oh-my-zsh setup
  --skip-tools     Skip uv, language runtimes, and extra developer tools
  --with-tpm       Install tmux plugin manager
  --proxmox-guest-agent
                  Install and enable qemu-guest-agent for Proxmox/QEMU VMs
  --create-admin-user
                  Create a normal sudo admin user from a root first-boot shell
  --tmux-prefix VALUE
                  ctrl-a or ctrl-b
  --save-setup-preferences
                  Save non-secret setup preferences to ~/.config/dotfiles/setup.env
  --load-setup-preferences
                  Load non-secret setup preferences before applying CLI flags
  --dry-run        Print resolved choices and exit without changing the system
  --no-powerlevel10k
                  Use the default oh-my-zsh prompt instead of Powerlevel10k
  --target-version VALUE
                  Expected Ubuntu VERSION_ID, for example 26.04
  --admin-user-current
                  Add the login user that runs setup to the sudo group
  --admin-user VALUE
                  Create the user if needed and add it to the sudo group
  --no-admin-user
                  Skip sudo user setup
  --apt-packages LIST
                  Install exactly these apt packages, comma separated
  --optional-packages LIST
                  Install only these optional apt packages, comma separated
  --no-optional-packages
                  Skip optional apt packages
  --extra-packages LIST
                  Add extra apt packages, comma separated
  --docker-strategy VALUE
                  official, distro, podman, or none
  --node-strategy VALUE
                  mise, nvm, or none
  --node-package-manager VALUE
                  pnpm, yarn, or npm
  --python-strategy VALUE
                  system-uv, mise, or none
  --java-strategy VALUE
                  mise-temurin-21, distro-openjdk-21, or none
  --developer-tools LIST
                  Install selected tools: rust,go,bun,deno,gh,ruby,dotnet
  --no-developer-tools
                  Skip extra developer tools
  --agent-tools LIST
                  Install selected npm agent CLIs: claude-code,openai-codex
  --no-agent-tools
                  Skip npm agent CLI installation
  -h, --help       Show this help

Examples:
  ./setup.sh ubuntu
  ./setup.sh ubuntu --yes
  ./Ubuntu/setup-ubuntu.sh --create-admin-user --admin-user ozz
  ./Ubuntu/setup-ubuntu.sh --yes --with-tpm
USAGE
}

for arg in "$@"; do
  if [[ "$arg" == "--load-setup-preferences" ]]; then
    LOAD_SETUP_PREFERENCES=1
    load_setup_preferences
    break
  fi
done

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -y|--yes)
      YES=1
      shift
      ;;
    --skip-apt)
      SKIP_APT=1
      shift
      ;;
    --skip-dotfiles)
      SKIP_DOTFILES=1
      shift
      ;;
    --skip-shell)
      SKIP_SHELL=1
      shift
      ;;
    --skip-tools)
      SKIP_TOOLS=1
      shift
      ;;
    --with-tpm)
      WITH_TPM=1
      shift
      ;;
    --proxmox-guest-agent)
      PROXMOX_GUEST_AGENT=1
      shift
      ;;
    --create-admin-user)
      CREATE_ADMIN_USER=1
      ADMIN_USER_MODE="selected"
      shift
      ;;
    --tmux-prefix)
      TMUX_PREFIX="${2:-}"
      case "$TMUX_PREFIX" in
        ctrl-a|ctrl-b) ;;
        *)
          printf 'Invalid --tmux-prefix: %s\n' "$TMUX_PREFIX" >&2
          exit 1
          ;;
      esac
      shift 2
      ;;
    --save-setup-preferences)
      SAVE_SETUP_PREFERENCES=1
      shift
      ;;
    --load-setup-preferences)
      LOAD_SETUP_PREFERENCES=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --no-powerlevel10k)
      POWERLEVEL10K=0
      shift
      ;;
    --target-version)
      TARGET_VERSION="${2:-}"
      if [[ -z "$TARGET_VERSION" ]]; then
        printf 'Missing value for --target-version\n' >&2
        exit 1
      fi
      shift 2
      ;;
    --admin-user-current)
      ADMIN_USER_MODE="current"
      ADMIN_USER_NAME=""
      shift
      ;;
    --admin-user)
      ADMIN_USER_MODE="selected"
      ADMIN_USER_NAME="${2:-}"
      if [[ -z "$ADMIN_USER_NAME" ]]; then
        printf 'Missing value for --admin-user\n' >&2
        exit 1
      fi
      shift 2
      ;;
    --no-admin-user)
      ADMIN_USER_MODE="none"
      ADMIN_USER_NAME=""
      shift
      ;;
    --apt-packages)
      APT_PACKAGE_MODE="selected"
      APT_PACKAGE_CSV="${2:-}"
      if [[ -z "$APT_PACKAGE_CSV" ]]; then
        printf 'Missing value for --apt-packages\n' >&2
        exit 1
      fi
      shift 2
      ;;
    --optional-packages)
      OPTIONAL_PACKAGE_MODE="selected"
      OPTIONAL_PACKAGE_CSV="${2:-}"
      if [[ -z "$OPTIONAL_PACKAGE_CSV" ]]; then
        printf 'Missing value for --optional-packages\n' >&2
        exit 1
      fi
      shift 2
      ;;
    --no-optional-packages)
      OPTIONAL_PACKAGE_MODE="none"
      shift
      ;;
    --extra-packages)
      EXTRA_PACKAGE_CSV="${2:-}"
      if [[ -z "$EXTRA_PACKAGE_CSV" ]]; then
        printf 'Missing value for --extra-packages\n' >&2
        exit 1
      fi
      shift 2
      ;;
    --docker-strategy)
      DOCKER_STRATEGY="${2:-}"
      case "$DOCKER_STRATEGY" in
        official|distro|podman|none) ;;
        *)
          printf 'Invalid --docker-strategy: %s\n' "$DOCKER_STRATEGY" >&2
          exit 1
          ;;
      esac
      shift 2
      ;;
    --node-strategy)
      NODE_STRATEGY="${2:-}"
      case "$NODE_STRATEGY" in
        mise|nvm|none) ;;
        *)
          printf 'Invalid --node-strategy: %s\n' "$NODE_STRATEGY" >&2
          exit 1
          ;;
      esac
      shift 2
      ;;
    --node-package-manager)
      NODE_PACKAGE_MANAGER="${2:-}"
      case "$NODE_PACKAGE_MANAGER" in
        pnpm|yarn|npm) ;;
        *)
          printf 'Invalid --node-package-manager: %s\n' "$NODE_PACKAGE_MANAGER" >&2
          exit 1
          ;;
      esac
      shift 2
      ;;
    --python-strategy)
      PYTHON_STRATEGY="${2:-}"
      case "$PYTHON_STRATEGY" in
        system-uv|mise|none) ;;
        *)
          printf 'Invalid --python-strategy: %s\n' "$PYTHON_STRATEGY" >&2
          exit 1
          ;;
      esac
      shift 2
      ;;
    --java-strategy)
      JAVA_STRATEGY="${2:-}"
      case "$JAVA_STRATEGY" in
        mise-temurin-21|distro-openjdk-21|none) ;;
        *)
          printf 'Invalid --java-strategy: %s\n' "$JAVA_STRATEGY" >&2
          exit 1
          ;;
      esac
      shift 2
      ;;
    --developer-tools)
      DEVELOPER_TOOL_MODE="selected"
      DEVELOPER_TOOL_CSV="${2:-}"
      if [[ -z "$DEVELOPER_TOOL_CSV" ]]; then
        printf 'Missing value for --developer-tools\n' >&2
        exit 1
      fi
      shift 2
      ;;
    --no-developer-tools)
      DEVELOPER_TOOL_MODE="none"
      DEVELOPER_TOOL_CSV=""
      shift
      ;;
    --agent-tools)
      AGENT_TOOL_MODE="selected"
      AGENT_TOOL_CSV="${2:-}"
      if [[ -z "$AGENT_TOOL_CSV" ]]; then
        printf 'Missing value for --agent-tools\n' >&2
        exit 1
      fi
      shift 2
      ;;
    --no-agent-tools)
      AGENT_TOOL_MODE="none"
      AGENT_TOOL_CSV=""
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

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

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

clone_or_update() {
  local url="$1"
  local dest="$2"

  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only
  else
    git clone --depth=1 "$url" "$dest"
  fi
}

backup_path() {
  local path="$1"

  if [[ -e "$path" || -L "$path" ]]; then
    local backup="${path}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$path" "$backup"
    printf 'Backed up %s to %s\n' "$path" "$backup"
  fi
}

link_file() {
  local source="$1"
  local target="$2"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return 0
  fi

  backup_path "$target"
  ln -s "$source" "$target"
  printf 'Linked %s\n' "$target"
}

load_package_file() {
  local file="$1"
  local -n __load_package_file_output_ref="$2"
  local line

  __load_package_file_output_ref=()

  if [[ ! -r "$file" ]]; then
    printf 'Package file not found: %s\n' "$file" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    __load_package_file_output_ref+=("$line")
  done <"$file"
}

split_csv() {
  local input="$1"
  local -n __split_csv_values_ref="$2"
  local item

  __split_csv_values_ref=()
  IFS=',' read -ra __split_csv_values_ref <<<"$input"
  for item in "${!__split_csv_values_ref[@]}"; do
    __split_csv_values_ref[$item]="${__split_csv_values_ref[$item]#"${__split_csv_values_ref[$item]%%[![:space:]]*}"}"
    __split_csv_values_ref[$item]="${__split_csv_values_ref[$item]%"${__split_csv_values_ref[$item]##*[![:space:]]}"}"
  done
}

filter_optional_packages() {
  local -n __filter_optional_packages_ref="$1"
  local selected=()
  local filtered=()
  local allowed
  local package
  local found

  case "$OPTIONAL_PACKAGE_MODE" in
    all)
      return 0
      ;;
    none)
      __filter_optional_packages_ref=()
      return 0
      ;;
    selected)
      split_csv "$OPTIONAL_PACKAGE_CSV" selected
      ;;
  esac

  for package in "${selected[@]}"; do
    [[ -z "$package" ]] && continue
    found=0
    for allowed in "${__filter_optional_packages_ref[@]}"; do
      if [[ "$package" == "$allowed" ]]; then
        filtered+=("$package")
        found=1
        break
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      warn "Ignoring unknown optional package: $package"
    fi
  done

  __filter_optional_packages_ref=("${filtered[@]}")
}

append_csv_packages() {
  local input="$1"
  local -n __append_csv_packages_output_ref="$2"
  local parsed=()
  local package

  [[ -z "$input" ]] && return 0
  split_csv "$input" parsed
  for package in "${parsed[@]}"; do
    [[ -z "$package" ]] && continue
    __append_csv_packages_output_ref+=("$package")
  done
}

resolve_apt_packages() {
  local output_name="$1"
  local -n __resolve_apt_packages_output_ref="$output_name"
  local core_packages=()
  local optional_packages=()

  __resolve_apt_packages_output_ref=()

  case "$APT_PACKAGE_MODE" in
    default)
      load_package_file "$PACKAGE_DIR/core.txt" core_packages
      load_package_file "$PACKAGE_DIR/optional.txt" optional_packages || warn 'No optional apt package file loaded.'
      filter_optional_packages optional_packages
      __resolve_apt_packages_output_ref=("${core_packages[@]}" "${optional_packages[@]}")
      ;;
    selected)
      append_csv_packages "$APT_PACKAGE_CSV" "$output_name"
      ;;
  esac

  append_csv_packages "$EXTRA_PACKAGE_CSV" "$output_name"
  if [[ "$PROXMOX_GUEST_AGENT" -eq 1 ]]; then
    __resolve_apt_packages_output_ref+=("qemu-guest-agent")
  fi
  dedupe_packages "$output_name"
}

dedupe_packages() {
  local -n __dedupe_packages_ref="$1"
  local seen=" "
  local deduped=()
  local package

  for package in "${__dedupe_packages_ref[@]}"; do
    [[ -z "$package" ]] && continue
    if [[ "$seen" != *" $package "* ]]; then
      deduped+=("$package")
      seen+="$package "
    fi
  done

  __dedupe_packages_ref=("${deduped[@]}")
}

detect_ubuntu() {
  if [[ ! -r /etc/os-release ]]; then
    warn 'Cannot read /etc/os-release; continuing without release checks.'
    return 0
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    warn "This script is tuned for Ubuntu, detected ${PRETTY_NAME:-unknown}."
    confirm 'Continue anyway?' || exit 1
  fi

  if [[ "${VERSION_ID:-}" == "25.04" ]]; then
    warn 'Ubuntu 25.04 reached end of life on 2026-01-15.'
    warn 'Use Ubuntu 24.04 LTS or 26.04 LTS when possible.'
    confirm 'Continue with Ubuntu 25.04 setup?' || exit 1
  fi

  if [[ -n "$TARGET_VERSION" && "${VERSION_ID:-}" != "$TARGET_VERSION" ]]; then
    warn "Target version is $TARGET_VERSION, detected ${VERSION_ID:-unknown}."
    confirm 'Continue with the detected Ubuntu version?' || exit 1
  fi
}

resolve_admin_user_name() {
  local current_user

  case "$ADMIN_USER_MODE" in
    none)
      return 1
      ;;
    selected)
      printf '%s\n' "$ADMIN_USER_NAME"
      ;;
    current)
      current_user="${SUDO_USER:-${USER:-}}"
      if [[ -z "$current_user" ]]; then
        current_user="$(id -un)"
      fi
      printf '%s\n' "$current_user"
      ;;
  esac
}

validate_admin_user_name() {
  local user_name="$1"

  is_valid_admin_user_name "$user_name"
}

prompt_admin_user_name() {
  local user_name

  if [[ ! -r /dev/tty ]]; then
    printf 'A TTY is required to prompt for a new admin username.\n' >&2
    return 1
  fi

  printf 'New admin username: ' >/dev/tty
  IFS= read -r user_name </dev/tty
  if ! validate_admin_user_name "$user_name"; then
    printf 'Invalid admin user name: %s\n' "$user_name" >&2
    return 1
  fi

  ADMIN_USER_MODE="selected"
  ADMIN_USER_NAME="$user_name"
}

prompt_admin_user_password() {
  local user_name="$1"
  local password
  local password_confirm
  local attempt

  if [[ ! -r /dev/tty ]]; then
    printf 'A TTY is required to prompt for the new admin password.\n' >&2
    return 1
  fi

  for attempt in 1 2 3; do
    printf 'New password for %s: ' "$user_name" >/dev/tty
    IFS= read -rs password </dev/tty
    printf '\n' >/dev/tty
    printf 'Confirm password for %s: ' "$user_name" >/dev/tty
    IFS= read -rs password_confirm </dev/tty
    printf '\n' >/dev/tty

    if [[ -z "$password" ]]; then
      printf 'Password cannot be empty.\n' >&2
    elif [[ "$password" == "$password_confirm" ]]; then
      printf '%s:%s\n' "$user_name" "$password" | chpasswd
      unset password password_confirm
      return 0
    else
      printf 'Passwords did not match.\n' >&2
    fi

    unset password password_confirm
  done

  printf 'Could not confirm password after 3 attempts.\n' >&2
  return 1
}

admin_group_name() {
  if getent group sudo >/dev/null 2>&1; then
    printf 'sudo\n'
  elif getent group wheel >/dev/null 2>&1; then
    printf 'wheel\n'
  else
    printf 'sudo\n'
  fi
}

create_admin_user_from_root() {
  local admin_user
  local group_name

  if [[ "$CREATE_ADMIN_USER" -eq 0 ]]; then
    return 0
  fi

  if [[ "$(id -u)" -ne 0 ]]; then
    printf '%s\n' '--create-admin-user must be run as root.' >&2
    return 1
  fi

  if [[ -z "$ADMIN_USER_NAME" ]]; then
    prompt_admin_user_name
  fi

  admin_user="$ADMIN_USER_NAME"
  if ! validate_admin_user_name "$admin_user"; then
    printf 'Invalid admin user name: %s\n' "$admin_user" >&2
    return 1
  fi

  group_name="$(admin_group_name)"
  if id "$admin_user" >/dev/null 2>&1; then
    log "Admin user $admin_user already exists"
  else
    log "Creating admin user $admin_user"
    useradd -m -s /bin/bash "$admin_user"
    prompt_admin_user_password "$admin_user"
  fi

  log "Granting $group_name access to $admin_user"
  usermod -aG "$group_name" "$admin_user"

  if [[ "$SAVE_SETUP_PREFERENCES" -eq 1 ]]; then
    save_setup_preferences
  fi

  log 'First-boot admin user is ready'
  printf 'Next: su - %s\n' "$admin_user"
  printf 'Then rerun dotfiles setup as %s, for example:\n' "$admin_user"
  printf '  ./setup.sh ubuntu --yes --load-setup-preferences\n'
}

add_admin_user_to_group() {
  local group_name="$1"
  local admin_user

  admin_user="$(resolve_admin_user_name)" || return 0
  if getent group "$group_name" >/dev/null 2>&1; then
    sudo usermod -aG "$group_name" "$admin_user" || warn "Could not add $admin_user to $group_name."
  fi
}

ensure_admin_user() {
  local admin_user
  local shell_path

  if [[ "$ADMIN_USER_MODE" == "none" ]]; then
    log 'Skipping admin user setup'
    return 0
  fi

  admin_user="$(resolve_admin_user_name)"
  if ! validate_admin_user_name "$admin_user"; then
    printf 'Invalid admin user name: %s\n' "$admin_user" >&2
    return 1
  fi

  shell_path="$(command -v zsh || printf '/bin/bash')"
  if id "$admin_user" >/dev/null 2>&1; then
    log "Ensuring $admin_user has sudo access"
  else
    log "Creating admin user $admin_user"
    sudo useradd -m -s "$shell_path" "$admin_user"
    warn "Set a password or SSH key for $admin_user before using that account for login."
  fi

  sudo usermod -aG sudo "$admin_user"
  add_admin_user_to_group docker
}

enable_ubuntu_universe() {
  if [[ ! -r /etc/os-release ]]; then
    warn 'Cannot read /etc/os-release; skipping universe repository setup.'
    return 0
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    return 0
  fi

  log 'Enabling Ubuntu universe repository'
  sudo apt install -y software-properties-common
  sudo add-apt-repository -y universe
  sudo apt update
}

enable_qemu_guest_agent() {
  if [[ "$PROXMOX_GUEST_AGENT" -eq 0 ]]; then
    return 0
  fi

  log 'Enabling qemu guest agent'
  if ! command -v systemctl >/dev/null 2>&1; then
    printf 'systemctl is required to enable qemu-guest-agent.\n' >&2
    return 1
  fi
  if ! systemctl list-unit-files qemu-guest-agent.service >/dev/null 2>&1; then
    printf 'qemu-guest-agent service unit was not found after package install.\n' >&2
    return 1
  fi

  sudo systemctl enable --now qemu-guest-agent
}

install_apt_packages() {
  local packages=()

  log 'Updating apt packages'
  sudo apt update
  enable_ubuntu_universe
  resolve_apt_packages packages

  log 'Upgrading apt packages'
  sudo apt upgrade -y

  if [[ "${#packages[@]}" -gt 0 ]]; then
    log 'Installing apt packages'
    sudo apt install -y "${packages[@]}"
  else
    log 'Skipping apt package install'
  fi

  enable_qemu_guest_agent
  install_container_runtime

  if command -v docker >/dev/null 2>&1; then
    add_admin_user_to_group docker
  fi

  mkdir -p "$HOME/.local/bin"
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi
}

install_container_runtime() {
  case "$DOCKER_STRATEGY" in
    official)
      install_docker_official
      ;;
    distro)
      install_docker_distro
      ;;
    podman)
      install_podman
      ;;
    none)
      log 'Skipping container runtime'
      ;;
  esac
}

install_docker_official() {
  local suite

  log 'Installing Docker from official repository'
  sudo apt update
  sudo apt install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # shellcheck disable=SC1091
  . /etc/os-release
  suite="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  if [[ -z "$suite" ]]; then
    warn 'Cannot determine Ubuntu codename for Docker apt source.'
    return 1
  fi

  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $suite
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_distro() {
  log 'Installing Docker from Ubuntu packages'
  sudo apt install -y docker.io docker-compose-v2
}

install_podman() {
  log 'Installing Podman compatibility tools'
  sudo apt install -y podman podman-docker
}

install_shell() {
  local zsh_custom
  zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  log 'Installing zsh setup'
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  mkdir -p "$zsh_custom/themes" "$zsh_custom/plugins"
  if [[ "$POWERLEVEL10K" -eq 1 ]]; then
    clone_or_update https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
  fi
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$zsh_custom/plugins/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-completions.git "$zsh_custom/plugins/zsh-completions"

  if command -v zsh >/dev/null 2>&1 && [[ "${SHELL:-}" != "$(command -v zsh)" ]]; then
    if confirm 'Set zsh as the login shell?'; then
      chsh -s "$(command -v zsh)"
    fi
  fi
}

write_tmux_prefix_override() {
  local prefix="$1"
  local tmux_prefix
  local old_prefix
  local local_file="$HOME/.tmux.conf.local"
  local temp_file

  case "$prefix" in
    ctrl-a)
      tmux_prefix="C-a"
      old_prefix="C-b"
      ;;
    ctrl-b)
      tmux_prefix="C-b"
      old_prefix="C-a"
      ;;
    *)
      printf 'Invalid tmux prefix: %s\n' "$prefix" >&2
      return 1
      ;;
  esac

  temp_file="${local_file}.tmp.$$"
  if [[ -f "$local_file" ]]; then
    awk '
      /^# BEGIN DOTFILES TMUX PREFIX$/ { skip = 1; next }
      /^# END DOTFILES TMUX PREFIX$/ { skip = 0; next }
      skip != 1 { print }
    ' "$local_file" >"$temp_file"
  else
    : >"$temp_file"
  fi

  printf '\n# BEGIN DOTFILES TMUX PREFIX\n' >>"$temp_file"
  printf 'set -g prefix %s\n' "$tmux_prefix" >>"$temp_file"
  printf 'unbind %s\n' "$old_prefix" >>"$temp_file"
  printf 'bind %s send-prefix\n' "$tmux_prefix" >>"$temp_file"
  printf '# END DOTFILES TMUX PREFIX\n' >>"$temp_file"

  mv "$temp_file" "$local_file"
  chmod 600 "$local_file"
  printf 'Updated %s\n' "$local_file"
}

install_dotfiles() {
  log 'Installing dotfiles'
  link_file "$CONFIG_DIR/.zshrc" "$HOME/.zshrc"
  link_file "$CONFIG_DIR/.vimrc" "$HOME/.vimrc"
  link_file "$CONFIG_DIR/.tmux.conf" "$HOME/.tmux.conf"
  link_file "$CONFIG_DIR/.gitconfig" "$HOME/.gitconfig"
  link_file "$CONFIG_DIR/.gitexclude" "$HOME/.gitexclude"

  if [[ ! -e "$HOME/.gitconfig.local" ]]; then
    cat >"$HOME/.gitconfig.local" <<'LOCAL_GITCONFIG'
[user]
	name =
	email =
LOCAL_GITCONFIG
    printf 'Created %s\n' "$HOME/.gitconfig.local"
  fi

  if [[ -n "$TMUX_PREFIX" ]]; then
    write_tmux_prefix_override "$TMUX_PREFIX"
  fi

  if [[ "$POWERLEVEL10K" -eq 0 ]]; then
    if [[ ! -e "$HOME/.zshrc.local" ]]; then
      cat >"$HOME/.zshrc.local" <<'LOCAL_ZSHRC'
export DOTFILES_POWERLEVEL10K=0
LOCAL_ZSHRC
      printf 'Created %s\n' "$HOME/.zshrc.local"
    elif ! grep -q '^export DOTFILES_POWERLEVEL10K=' "$HOME/.zshrc.local"; then
      printf '\nexport DOTFILES_POWERLEVEL10K=0\n' >>"$HOME/.zshrc.local"
      printf 'Updated %s\n' "$HOME/.zshrc.local"
    fi
  fi
}

install_vim_plug() {
  log 'Installing vim-plug'
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  if command -v vim >/dev/null 2>&1; then
    DOTFILES_SKIP_NETWORK=1 vim +PlugInstall +qall
  fi
}

install_tpm() {
  if [[ "$WITH_TPM" -ne 1 ]]; then
    return 0
  fi

  log 'Installing tmux plugin manager'
  clone_or_update https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}

install_uv() {
  log 'Installing uv'
  if command -v uv >/dev/null 2>&1; then
    uv self update || true
  else
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
}

install_rust() {
  log 'Installing Rust toolchain'
  local rustup_bin="$HOME/.cargo/bin/rustup"

  if ! command -v rustup >/dev/null 2>&1 && [[ ! -x "$rustup_bin" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile default
  fi

  if command -v rustup >/dev/null 2>&1; then
    rustup default stable
    rustup component add rustfmt clippy
  elif [[ -x "$rustup_bin" ]]; then
    "$rustup_bin" default stable
    "$rustup_bin" component add rustfmt clippy
  fi
}

install_mise() {
  log 'Installing mise'
  local mise_bin="$HOME/.local/bin/mise"

  if ! command -v mise >/dev/null 2>&1 && [[ ! -x "$mise_bin" ]]; then
    curl -fsSL https://mise.run | sh
  fi

  export PATH="$HOME/.local/bin:$PATH"
  if command -v mise >/dev/null 2>&1 || [[ -x "$mise_bin" ]]; then
    return 0
  fi

  warn 'mise was not found after install.'
  return 1
}

mise_use_global() {
  install_mise || return 1
  local mise_bin="$HOME/.local/bin/mise"

  if command -v mise >/dev/null 2>&1; then
    mise use -g "$@"
  elif [[ -x "$mise_bin" ]]; then
    "$mise_bin" use -g "$@"
  else
    return 1
  fi
}

mise_enable_idiomatic_version_file() {
  install_mise || return 1
  local tool="$1"
  local mise_bin="$HOME/.local/bin/mise"
  local mise_cmd=()

  if command -v mise >/dev/null 2>&1; then
    mise_cmd=(mise)
  elif [[ -x "$mise_bin" ]]; then
    mise_cmd=("$mise_bin")
  else
    return 1
  fi

  local current_settings
  current_settings="$("${mise_cmd[@]}" settings get idiomatic_version_file_enable_tools 2>/dev/null || true)"
  if [[ "$current_settings" == *"$tool"* ]]; then
    return 0
  fi

  "${mise_cmd[@]}" settings add idiomatic_version_file_enable_tools "$tool" >/dev/null 2>&1 || true
}

install_mise_and_node() {
  log 'Installing Node LTS through mise'
  mise_use_global node@lts || warn 'Node LTS setup through mise skipped.'
  mise_enable_idiomatic_version_file node
}

install_nvm_and_node() {
  log 'Installing nvm and Node LTS'
  if [[ ! -d "$HOME/.nvm" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
  fi

  # shellcheck disable=SC1091
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default 'lts/*'
  else
    warn 'nvm was not found after install; Node LTS setup skipped.'
  fi
}

run_node_command() {
  local mise_bin="$HOME/.local/bin/mise"

  if [[ "$NODE_STRATEGY" == "mise" ]]; then
    if command -v mise >/dev/null 2>&1; then
      mise exec node@lts -- "$@"
      return $?
    fi

    if [[ -x "$mise_bin" ]]; then
      "$mise_bin" exec node@lts -- "$@"
      return $?
    fi

    warn 'mise was not found for Node command.'
    return 1
  fi

  if command -v "$1" >/dev/null 2>&1; then
    "$@"
    return $?
  fi

  if command -v mise >/dev/null 2>&1; then
    mise exec node@lts -- "$@"
    return $?
  fi

  if [[ -x "$mise_bin" ]]; then
    "$mise_bin" exec node@lts -- "$@"
    return $?
  fi

  warn "Node command not found: $1"
  return 1
}

install_node_package_manager() {
  if [[ "$NODE_STRATEGY" == "none" ]]; then
    log 'Skipping Node package manager setup'
    return 0
  fi

  case "$NODE_PACKAGE_MANAGER" in
    pnpm)
      log 'Enabling pnpm through Corepack'
      run_node_command corepack enable pnpm || warn 'Could not enable pnpm through Corepack.'
      run_node_command corepack prepare pnpm@latest --activate || warn 'Could not activate latest pnpm.'
      ;;
    yarn)
      log 'Enabling Yarn through Corepack'
      run_node_command corepack enable yarn || warn 'Could not enable Yarn through Corepack.'
      run_node_command corepack prepare yarn@stable --activate || warn 'Could not activate stable Yarn.'
      ;;
    npm)
      log 'Using npm bundled with Node'
      ;;
  esac
}

install_python_runtime() {
  case "$PYTHON_STRATEGY" in
    system-uv)
      log 'Using system Python packages with uv'
      ;;
    mise)
      log 'Installing Python through mise'
      mise_use_global python@latest || warn 'Python setup through mise skipped.'
      mise_enable_idiomatic_version_file python
      ;;
    none)
      log 'Skipping extra Python runtime setup'
      ;;
  esac
}

resolve_developer_tools() {
  local -n __resolve_developer_tools_ref="$1"
  local selected=()
  local tool

  __resolve_developer_tools_ref=()

  case "$DEVELOPER_TOOL_MODE" in
    none)
      return 0
      ;;
    default|selected)
      split_csv "$DEVELOPER_TOOL_CSV" selected
      ;;
  esac

  for tool in "${selected[@]}"; do
    case "$tool" in
      rust|go|bun|deno|gh|ruby|dotnet)
        __resolve_developer_tools_ref+=("$tool")
        ;;
      *)
        warn "Ignoring unknown developer tool: $tool"
        ;;
    esac
  done
}

install_github_cli() {
  log 'Installing GitHub CLI from official repository'
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
    "$(dpkg --print-architecture)" |
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update
  sudo apt install -y gh
}

install_mise_tool() {
  local tool="$1"
  local label="$2"

  log "Installing $label through mise"
  mise_use_global "$tool" || warn "$label setup through mise skipped."
}

install_developer_tools() {
  local tools=()
  local tool

  resolve_developer_tools tools
  if [[ "${#tools[@]}" -eq 0 ]]; then
    log 'Skipping extra developer tools'
    return 0
  fi

  for tool in "${tools[@]}"; do
    case "$tool" in
      rust)
        install_rust
        ;;
      go)
        install_mise_tool go@latest Go
        ;;
      bun)
        install_mise_tool bun@latest Bun
        ;;
      deno)
        install_mise_tool deno@latest Deno
        ;;
      gh)
        install_github_cli || warn 'GitHub CLI setup skipped.'
        ;;
      ruby)
        install_mise_tool ruby@latest Ruby
        ;;
      dotnet)
        install_mise_tool dotnet@latest dotnet
        ;;
    esac
  done
}

install_java_runtime() {
  case "$JAVA_STRATEGY" in
    mise-temurin-21)
      log 'Installing Temurin 21 through mise'
      mise_use_global java@temurin-21 || warn 'Java setup through mise skipped.'
      ;;
    distro-openjdk-21)
      log 'Installing OpenJDK 21 from Ubuntu packages'
      sudo apt install -y openjdk-21-jdk
      ;;
    none)
      log 'Skipping Java runtime setup'
      ;;
  esac
}

resolve_agent_tool_packages() {
  local -n __resolve_agent_tool_packages_ref="$1"
  local selected=()
  local tool

  __resolve_agent_tool_packages_ref=()

  case "$AGENT_TOOL_MODE" in
    none)
      return 0
      ;;
    default|selected)
      split_csv "$AGENT_TOOL_CSV" selected
      ;;
  esac

  for tool in "${selected[@]}"; do
    case "$tool" in
      claude-code)
        __resolve_agent_tool_packages_ref+=("@anthropic-ai/claude-code")
        ;;
      openai-codex)
        __resolve_agent_tool_packages_ref+=("@openai/codex")
        ;;
      *)
        warn "Ignoring unknown agent tool: $tool"
        ;;
    esac
  done
}

install_global_npm_packages() {
  local packages=("$@")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    return 0
  fi

  run_node_command npm install -g "${packages[@]}"
}

install_agent_tools() {
  local packages=()

  if [[ "$NODE_STRATEGY" == "none" && "$AGENT_TOOL_MODE" == "default" ]]; then
    log 'Skipping agent CLIs because Node setup is disabled'
    return 0
  fi

  resolve_agent_tool_packages packages
  if [[ "${#packages[@]}" -eq 0 ]]; then
    log 'Skipping agent CLIs'
    return 0
  fi

  log 'Installing npm agent CLIs'
  install_global_npm_packages "${packages[@]}" || true
}

install_tools() {
  install_uv
  install_python_runtime
  case "$NODE_STRATEGY" in
    mise)
      install_mise_and_node
      ;;
    nvm)
      install_nvm_and_node
      ;;
    none)
      log 'Skipping Node runtime setup'
      ;;
  esac
  install_node_package_manager
  install_agent_tools
  install_developer_tools
  install_java_runtime
}

print_plan() {
  local packages=()

  if [[ "$SKIP_APT" -eq 0 ]]; then
    resolve_apt_packages packages
  fi

  log 'Dry run'
  printf 'Target version: %s\n' "${TARGET_VERSION:-not set}"
  printf 'Load setup preferences: %s\n' "$([[ "$LOAD_SETUP_PREFERENCES" -eq 1 ]] && printf yes || printf no)"
  printf 'Save setup preferences: %s\n' "$([[ "$SAVE_SETUP_PREFERENCES" -eq 1 ]] && printf yes || printf no)"
  printf 'Setup preferences file: %s\n' "$SETUP_PREFERENCES_FILE"
  printf 'Create admin user first: %s\n' "$([[ "$CREATE_ADMIN_USER" -eq 1 ]] && printf yes || printf no)"
  case "$ADMIN_USER_MODE" in
    current)
      printf 'Admin user: current login user\n'
      ;;
    selected)
      printf 'Admin user: %s\n' "$ADMIN_USER_NAME"
      ;;
    none)
      printf 'Admin user: disabled\n'
      ;;
  esac
  if [[ "$CREATE_ADMIN_USER" -eq 1 ]]; then
    printf 'First-boot admin setup requires root and stops before apt, shell, dotfiles, and tools.\n'
    printf 'Password would be prompted interactively with hidden input and never displayed or stored.\n'
    printf 'Admin group would be granted with sudo/wheel group membership.\n'
  fi
  printf 'Apt step: %s\n' "$([[ "$SKIP_APT" -eq 0 ]] && printf enabled || printf skipped)"
  printf 'Shell step: %s\n' "$([[ "$SKIP_SHELL" -eq 0 ]] && printf enabled || printf skipped)"
  printf 'Dotfile step: %s\n' "$([[ "$SKIP_DOTFILES" -eq 0 ]] && printf enabled || printf skipped)"
  printf 'Tools step: %s\n' "$([[ "$SKIP_TOOLS" -eq 0 ]] && printf enabled || printf skipped)"
  printf 'Docker strategy: %s\n' "$DOCKER_STRATEGY"
  printf 'Node strategy: %s\n' "$NODE_STRATEGY"
  printf 'Node package manager: %s\n' "$([[ "$NODE_STRATEGY" == "none" ]] && printf none || printf '%s' "$NODE_PACKAGE_MANAGER")"
  printf 'Python strategy: %s\n' "$PYTHON_STRATEGY"
  printf 'Java strategy: %s\n' "$JAVA_STRATEGY"
  printf 'Developer tools: %s\n' "${DEVELOPER_TOOL_CSV:-none}"
  printf 'Agent tools: %s\n' "${AGENT_TOOL_CSV:-none}"
  printf 'Proxmox guest agent: %s\n' "$([[ "$PROXMOX_GUEST_AGENT" -eq 1 ]] && printf yes || printf no)"
  printf 'Powerlevel10k: %s\n' "$([[ "$POWERLEVEL10K" -eq 1 ]] && printf yes || printf no)"
  printf 'Install TPM: %s\n' "$([[ "$WITH_TPM" -eq 1 ]] && printf yes || printf no)"
  printf 'Tmux prefix: %s\n' "${TMUX_PREFIX:-repo default}"
  printf 'Apt packages: %s\n' "${#packages[@]}"
  if [[ "${#packages[@]}" -gt 0 ]]; then
    printf '%s\n' "${packages[@]}"
  fi
}

main() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    print_plan
    exit 0
  fi

  detect_ubuntu

  if [[ "$CREATE_ADMIN_USER" -eq 1 ]]; then
    create_admin_user_from_root
    exit 0
  fi

  ensure_admin_user

  if [[ "$SKIP_APT" -eq 0 ]] && confirm 'Install apt packages?'; then
    install_apt_packages
  fi

  if [[ "$SKIP_SHELL" -eq 0 ]] && confirm 'Install zsh and shell plugins?'; then
    install_shell
  fi

  if [[ "$SKIP_DOTFILES" -eq 0 ]] && confirm 'Link dotfiles into home directory?'; then
    install_dotfiles
    install_vim_plug
    install_tpm
  fi

  if [[ "$SKIP_TOOLS" -eq 0 ]] && confirm 'Install uv, Rust, and selected language runtimes?'; then
    install_tools
  fi

  if [[ "$SAVE_SETUP_PREFERENCES" -eq 1 ]]; then
    save_setup_preferences
  fi

  log 'Finished'
  printf 'Open a new shell or run: source ~/.zshrc\n'
  printf 'If Docker was installed, log out and back in for group changes.\n'
}

main "$@"
