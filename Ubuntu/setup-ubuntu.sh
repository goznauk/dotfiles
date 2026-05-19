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
DRY_RUN=0
POWERLEVEL10K=1
APT_PACKAGE_MODE="default"
APT_PACKAGE_CSV=""
OPTIONAL_PACKAGE_MODE="all"
OPTIONAL_PACKAGE_CSV=""
EXTRA_PACKAGE_CSV=""
DOCKER_STRATEGY="official"
NODE_STRATEGY="mise"
PYTHON_STRATEGY="system-uv"
JAVA_STRATEGY="none"
TARGET_VERSION=""

usage() {
  cat <<'USAGE'
Usage:
  ./Ubuntu/setup-ubuntu.sh [options]

Options:
  -y, --yes        Run without confirmation prompts
  --skip-apt       Skip apt packages
  --skip-dotfiles  Skip dotfile links
  --skip-shell     Skip zsh and oh-my-zsh setup
  --skip-tools     Skip uv, rustup, and language runtime setup
  --with-tpm       Install tmux plugin manager
  --dry-run        Print resolved choices and exit without changing the system
  --no-powerlevel10k
                  Use the default oh-my-zsh prompt instead of Powerlevel10k
  --target-version VALUE
                  Expected Ubuntu VERSION_ID, for example 26.04
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
  --python-strategy VALUE
                  system-uv, mise, or none
  --java-strategy VALUE
                  mise-temurin-21, distro-openjdk-21, or none
  -h, --help       Show this help

Examples:
  ./setup.sh ubuntu
  ./setup.sh ubuntu --yes
  ./Ubuntu/setup-ubuntu.sh --yes --with-tpm
USAGE
}

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
  local -n output_packages="$2"
  local line

  output_packages=()

  if [[ ! -r "$file" ]]; then
    printf 'Package file not found: %s\n' "$file" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    output_packages+=("$line")
  done <"$file"
}

split_csv() {
  local input="$1"
  local -n values_ref="$2"
  local item

  values_ref=()
  IFS=',' read -ra values_ref <<<"$input"
  for item in "${!values_ref[@]}"; do
    values_ref[$item]="${values_ref[$item]#"${values_ref[$item]%%[![:space:]]*}"}"
    values_ref[$item]="${values_ref[$item]%"${values_ref[$item]##*[![:space:]]}"}"
  done
}

filter_optional_packages() {
  local -n optional_packages="$1"
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
      optional_packages=()
      return 0
      ;;
    selected)
      split_csv "$OPTIONAL_PACKAGE_CSV" selected
      ;;
  esac

  for package in "${selected[@]}"; do
    [[ -z "$package" ]] && continue
    found=0
    for allowed in "${optional_packages[@]}"; do
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

  optional_packages=("${filtered[@]}")
}

append_csv_packages() {
  local input="$1"
  local -n output_packages="$2"
  local parsed=()
  local package

  [[ -z "$input" ]] && return 0
  split_csv "$input" parsed
  for package in "${parsed[@]}"; do
    [[ -z "$package" ]] && continue
    output_packages+=("$package")
  done
}

resolve_apt_packages() {
  local output_name="$1"
  local -n output_packages="$output_name"
  local core_packages=()
  local optional_packages=()

  output_packages=()

  case "$APT_PACKAGE_MODE" in
    default)
      load_package_file "$PACKAGE_DIR/core.txt" core_packages
      load_package_file "$PACKAGE_DIR/optional.txt" optional_packages || warn 'No optional apt package file loaded.'
      filter_optional_packages optional_packages
      output_packages=("${core_packages[@]}" "${optional_packages[@]}")
      ;;
    selected)
      append_csv_packages "$APT_PACKAGE_CSV" "$output_name"
      ;;
  esac

  append_csv_packages "$EXTRA_PACKAGE_CSV" "$output_name"
  dedupe_packages "$output_name"
}

dedupe_packages() {
  local -n output_packages="$1"
  local seen=" "
  local deduped=()
  local package

  for package in "${output_packages[@]}"; do
    [[ -z "$package" ]] && continue
    if [[ "$seen" != *" $package "* ]]; then
      deduped+=("$package")
      seen+="$package "
    fi
  done

  output_packages=("${deduped[@]}")
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

install_apt_packages() {
  local packages=()

  resolve_apt_packages packages

  log 'Updating apt packages'
  sudo apt update
  sudo apt upgrade -y

  if [[ "${#packages[@]}" -gt 0 ]]; then
    log 'Installing apt packages'
    sudo apt install -y "${packages[@]}"
  else
    log 'Skipping apt package install'
  fi

  install_container_runtime

  if command -v docker >/dev/null 2>&1; then
    sudo usermod -aG docker "$USER" || warn 'Could not add current user to docker group.'
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

install_tools() {
  install_uv
  install_rust
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
  install_java_runtime
}

print_plan() {
  local packages=()

  if [[ "$SKIP_APT" -eq 0 ]]; then
    resolve_apt_packages packages
  fi

  log 'Dry run'
  printf 'Target version: %s\n' "${TARGET_VERSION:-not set}"
  printf 'Apt step: %s\n' "$([[ "$SKIP_APT" -eq 0 ]] && printf enabled || printf skipped)"
  printf 'Shell step: %s\n' "$([[ "$SKIP_SHELL" -eq 0 ]] && printf enabled || printf skipped)"
  printf 'Dotfile step: %s\n' "$([[ "$SKIP_DOTFILES" -eq 0 ]] && printf enabled || printf skipped)"
  printf 'Tools step: %s\n' "$([[ "$SKIP_TOOLS" -eq 0 ]] && printf enabled || printf skipped)"
  printf 'Docker strategy: %s\n' "$DOCKER_STRATEGY"
  printf 'Node strategy: %s\n' "$NODE_STRATEGY"
  printf 'Python strategy: %s\n' "$PYTHON_STRATEGY"
  printf 'Java strategy: %s\n' "$JAVA_STRATEGY"
  printf 'Powerlevel10k: %s\n' "$([[ "$POWERLEVEL10K" -eq 1 ]] && printf yes || printf no)"
  printf 'Install TPM: %s\n' "$([[ "$WITH_TPM" -eq 1 ]] && printf yes || printf no)"
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

  log 'Finished'
  printf 'Open a new shell or run: source ~/.zshrc\n'
  printf 'If Docker was installed, log out and back in for group changes.\n'
}

main "$@"
