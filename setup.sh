#!/bin/bash

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
SETTINGDIR=$DIR/common
ENVPATH=$BASEDIR/.env
source $ENVPATH

echo -e "${GREEN}
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░
░░░░░░░███░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░░░░░░░░░░░█░░░░░░░░
░░░░░░██░░░░░░░░░░░░░░████░░░░░░░░░░████░░░░░░░░░░░░█░░░░░░░░
░░░░░██░░░░██░░░███░░██░██░░█░░███░░█░░█░░░█░░█░░░░██░░█░░░░░
░░░░░█░░░████░░██░██░░░░█░░░█░██░█░░░░░█░░░█░░██░░░█████░░░░░
░░░░░█░████░█░██░░░█░░░█░░░░███░░█░░████░░░█░░██░░░███░░░░░░░
░░░░░█░░░░█░█░██░░██░░█░░░░░██░░░█░░█░████░██████░██░██░░░░░░
░░░░░██░░██░█░░████░░██████░█░░░░░░░███░░░░░██░░░░█░░░██░░░░░
░░░░░░░██░░░█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░█████░░░░░░░░░░░░░░░░░███████░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░███░░████░░░░░░░░░░░░██░░░░░░░██░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░█░░░░░░░░█░░░░░░░░░░░█░░░░░░░░██░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░█░░░░░░██░░░░░░░░░░░████░░░███░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░███████░░░░░░░░░░░░░░░████░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░███░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░███░░░░░░░░░░░░░░░░░░░█████░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░██████░░░░░░░░░░░░░██████░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░█████████████████████░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░██████████████░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
${NC}"

echo ░░ Install with environment variable at $ENVPATH

if [ "$OS" = "DEBIAN" ]; then
    echo -e "░░ Installing on ${BLUE}Debian${NC}"
    ENVPATH=$ENVPATH ./Ubuntu/setup-ubuntu.sh

elif [ "$OS" = "MACOS" ]; then
    echo -e "░░ Installing on ${BLUE}macOS${NC}."
    ENVPATH=$ENVPATH ./MacOS/setup-mac.sh

else

    echo -e "${RED}░░ ERROR: OS not defined${NC}"
    echo -e "${RED}░░ Please choose OS in .env files${NC}"
    exit 100
fi

# oh my zsh
echo -e "░░ Installing ${RED}Zsh Configuration${NC}"
echo -e "░░ ${BLUE}ohmyzsh, powerlevel10k, zsh-syntax-highlighting, zsh-autosuggestions${NC}"
echo -n "░░ continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    cp -v "$SETTINGDIR/.zshrc" "$HOME/.zshrc"
fi

# git
echo -e "░░ Installing ${RED}Git Configuration${NC}"
echo -e "░░ ${BLUE}.gitconfig .gitignore${NC}"
echo -n "░░ continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    ln -sf "$SETTINGDIR/.gitexclude" "$HOME/.gitexclude"
    cp -v "$SETTINGDIR/.gitconfig" "$HOME/.gitconfig"
    echo -e "[user]\n\temail = $GIT_PROFILE_EMAIL\n\tname = $GIT_PROFILE_USERNAME" >>"$HOME/.gitconfig.local"
    if [ "$GIT_PROFILE_COMPANY_SEPERATE" = true ]; then
        mkdir -p "$GIT_PROFILE_COMPANY_REPOSITORY_DIR"
        echo -e "[user]\n\temail = $GIT_PROFILE_COMPANY_EMAIL\n\tname = $GIT_PROFILE_COMPANY_USERNAME" >>"$HOME/.gitconfig.$GIT_PROFILE_COMPANY_NAME"
        echo -e "[includeIf \"gitdir:$GIT_PROFILE_COMPANY_REPOSITORY_DIR\"]\n\tpath = .gitconfig.$GIT_PROFILE_COMPANY_NAME" >>"$HOME/.gitconfig.local"
    fi
fi

# vim
echo -e "░░ Installing ${RED}Vim Configuration${NC}"
echo -n "░░ continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    cp -v "$SETTINGDIR/.vimrc" "$HOME/.vimrc"
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +qall
fi

# tmux plugin manager
echo -e "░░ Installing ${RED}Tmux Configuration${NC}"
echo -n "░░ continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    cp -v "$SETTINGDIR/.tmux.conf" "$HOME/.tmux.conf"
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
    $HOME/.tmux/plugins/tpm/scripts/install_plugins.sh
fi

# nodejs
if command -v node &>/dev/null; then
    echo -e "░░ Setting up ${RED}node.js${NC}"
    echo -e "░░ ${BLUE}yarn, diff-so-fancy${NC}"
    echo -n "░░ continue? [y/N] "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        npm -g install yarn
        yarn global add diff-so-fancy
    fi
fi

echo -e "SCRIPT FINISHED\n\n"

exit 0
