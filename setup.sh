#!/bin/bash

RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  TARGET="$(readlink "$SOURCE")"
  if [[ $SOURCE == /* ]]; then
    SOURCE="$TARGET"
  else
    DIR="$(dirname "$SOURCE")"
    SOURCE="$DIR/$TARGET"
  fi
done
DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

BASEDIR=$DIR

source $BASEDIR/.env

echo $BASEDIR

if [ "$OS" = "DEBIAN" ]; then
  echo -e "Installing on debian. Use ${BLUE}apt${NC} to Install"

  # general server packages
  echo -e "Installing ${RED}Prerequisite${NC}"
  echo -e "${BLUE}$SERVER_PACKAGES${NC}"
  echo -n "continue? [y/N] "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    sudo apt update
    sudo apt upgrade
    sudo apt install -y $SERVER_PACKAGES
  fi

  # nodejs (v12)
  echo -e "Installing ${RED}NodeJS (v12)${NC}"
  echo -e "${BLUE}node, npm, yarn, diff-so-fancy${NC}"
  echo -n "continue? [y/N] "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
    sudo apt install -y nodejs
    sudo npm -g install yarn
    sudo yarn global add diff-so-fancy
  fi

  # Java10
  echo -e "Installing ${RED}Oracle Java10${NC}"
  echo -n "continue? [y/N] "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    sudo add-apt-repository ppa:linuxuprising/java
    sudo apt update
    sudo apt install oracle-java10-installer
  fi

elif [ "$OS" = "MACOS" ]; then
  echo -e "Installing on macos. Use ${BLUE}brew${NC} to Install"

  # general osx packages
  echo -e "Installing ${RED}Prerequisite${NC}"
  echo -e "${BLUE}$OSX_PACKAGES${NC}"
  echo -n "continue? [y/N] "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    brew install $OSX_PACKAGES
    brew cask install homebrew/cask-fonts/font-meslo-for-powerline
  fi

  # nodejs (v12)
  echo -e "Installing ${RED}NodeJS (v12)${NC}"
  echo -e "${BLUE}node, npm, yarn, diff-so-fancy${NC}"
  echo -n "continue? [y/N] "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    brew install node
    npm -g install yarn
    yarn global add diff-so-fancy
  fi

else
  echo -e "${RED}ERROR: OS not defined${NC}"
  echo -e "${RED}Please choose OS in .env files${NC}"
  exit 100
fi

# oh my zsh
echo -e "Installing ${RED}Zsh Configuration${NC}"
echo -e "${BLUE}ohmyzsh, powerlevel10k, zsh-syntax-highlighting, zsh-autosuggestions${NC}"
echo -n "continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
  git clone https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
  # sh -c "$(curl -fsSL https://raw.githubusercontent.com/goznauk/zinit/master/doc/install.sh)"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
  cp -v "$BASEDIR/.zshrc" "$HOME/.zshrc"
fi

# git
echo -e "Installing ${RED}Git Configuration${NC}"
echo -e "${BLUE}.gitconfig .gitignore${NC}"
echo -n "continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  ln -sf "$BASEDIR/.gitexclude" "$HOME/.gitexclude"
  ln -sf "$BASEDIR/.gitconfig" "$HOME/.gitconfig"
  echo -e "[user]\n\temail = $GIT_PROFILE_EMAIL\n\tname = $GIT_PROFILE_USERNAME" >>"$HOME/.gitconfig.local"
  if [ $GIT_PROFILE_COMPANY_SEPERATE = true ]; then
    mkdir -p "$GIT_PROFILE_COMPANY_REPOSITORY_DIR"
    echo -e "[user]\n\temail = $GIT_PROFILE_COMPANY_EMAIL\n\tname = $GIT_PROFILE_COMPANY_USERNAME" >>"$HOME/.gitconfig.$GIT_PROFILE_COMPANY_NAME"
    echo -e "[includeIf \"gitdir:$GIT_PROFILE_COMPANY_REPOSITORY_DIR\"]\n\tpath = .gitconfig.$GIT_PROFILE_COMPANY_NAME" >>"$HOME/.gitconfig.local"
  fi
fi

# vim
echo -e "Installing ${RED}Vim Configuration${NC}"
echo -n "continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  ln -sf "$BASEDIR/.vimrc" "$HOME/.vimrc"
  git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
  vim +PluginInstall +qall
fi

# tmux plugin manager
echo -e "Installing ${RED}Tmux Configuration${NC}"
echo -n "continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  ln -sf "$BASEDIR/.tmux.conf" "$HOME/.tmux.conf"
  git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
  $HOME/.tmux/plugins/tpm/scripts/install_plugins.sh
fi

exit 0
