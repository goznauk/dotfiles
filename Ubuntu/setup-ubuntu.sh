#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/common"

YES=0
SKIP_APT=0
SKIP_DOTFILES=0
SKIP_SHELL=0
SKIP_TOOLS=0
WITH_TPM=0

usage() {
  cat <<'USAGE'
Usage:
  ./Ubuntu/setup-ubuntu.sh [options]

Options:
  -y, --yes        Run without confirmation prompts
  --skip-apt       Skip apt packages
  --skip-dotfiles  Skip dotfile links
  --skip-shell     Skip zsh and oh-my-zsh setup
  --skip-tools     Skip uv, rustup, and mise runtime setup
  --with-tpm       Install tmux plugin manager
  -h, --help       Show this help

Examples:
  ./setup.sh ubuntu
  ./setup.sh ubuntu --yes
  ./Ubuntu/setup-ubuntu.sh --yes --with-tpm
USAGE
}

for arg in "$@"; do
  case "$arg" in
    -y|--yes)
      YES=1
      ;;
    --skip-apt)
      SKIP_APT=1
      ;;
    --skip-dotfiles)
      SKIP_DOTFILES=1
      ;;
    --skip-shell)
      SKIP_SHELL=1
      ;;
    --skip-tools)
      SKIP_TOOLS=1
      ;;
    --with-tpm)
      WITH_TPM=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
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
}

install_apt_packages() {
  local core_packages=(
    apt-transport-https
    ca-certificates
    curl
    wget
    gnupg
    lsb-release
    software-properties-common
    build-essential
    pkg-config
    make
    cmake
    ninja-build
    autoconf
    automake
    libtool
    gcc
    g++
    clang
    lldb
    gdb
    git
    git-lfs
    zsh
    vim
    tmux
    rsync
    unzip
    zip
    xz-utils
    tar
    jq
    ripgrep
    fd-find
    fzf
    tree
    htop
    lsof
    net-tools
    iproute2
    dnsutils
    iputils-ping
    traceroute
    openssh-client
    python3
    python3-dev
    python3-venv
    python3-pip
    pipx
    sqlite3
    libssl-dev
    zlib1g-dev
    libbz2-dev
    libreadline-dev
    libsqlite3-dev
    libffi-dev
    liblzma-dev
    libncurses-dev
    tk-dev
    uuid-dev
    direnv
    shellcheck
    xclip
    wl-clipboard
  )

  local optional_packages=(
    btop
    bat
    eza
    git-extras
    hyperfine
    nmap
    openssh-server
    shfmt
    yq
    docker.io
    docker-compose-v2
  )

  log 'Updating apt packages'
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y "${core_packages[@]}"

  log 'Installing optional apt packages'
  for pkg in "${optional_packages[@]}"; do
    if ! sudo apt install -y "$pkg"; then
      warn "Skipped optional package: $pkg"
    fi
  done

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

install_shell() {
  local zsh_custom
  zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  log 'Installing zsh setup'
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  mkdir -p "$zsh_custom/themes" "$zsh_custom/plugins"
  clone_or_update https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
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

install_mise_and_node() {
  log 'Installing mise and Node LTS'
  local mise_bin="$HOME/.local/bin/mise"

  if ! command -v mise >/dev/null 2>&1 && [[ ! -x "$mise_bin" ]]; then
    curl -fsSL https://mise.run | sh
  fi

  if command -v mise >/dev/null 2>&1; then
    mise use -g node@lts
  elif [[ -x "$mise_bin" ]]; then
    "$mise_bin" use -g node@lts
  else
    warn 'mise was not found after install; Node LTS setup skipped.'
  fi
}

install_tools() {
  install_uv
  install_rust
  install_mise_and_node
}

main() {
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

  if [[ "$SKIP_TOOLS" -eq 0 ]] && confirm 'Install uv, Rust, mise, and Node LTS?'; then
    install_tools
  fi

  log 'Finished'
  printf 'Open a new shell or run: source ~/.zshrc\n'
  printf 'If Docker was installed, log out and back in for group changes.\n'
}

main "$@"
