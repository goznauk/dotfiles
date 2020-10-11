#!/bin/bash

source $ENVPATH

echo -e "░░ Install ${BLUE}brew${NC} if not exists"

if ! command -v brew &>/dev/null; then
    echo "░░ NO BREW DETECTED"
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# general osx packages
echo -e "░░ Installing ${RED}POSIX packages${NC}"
echo -e "░░ ${BLUE}$OSX_PACKAGES${NC}"
echo -n "░░ continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    echo -e "░░ Installing packages"
    brew install $OSX_PACKAGES
fi

# Java10
echo -e "░░ Installing ${RED}Java${NC}"
echo -n "░░ continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    brew cask install java
fi

exit 0
