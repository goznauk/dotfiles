#!/usr/bin/env bash

# shellcheck disable=SC1090
source "$ENVPATH"

echo -e "Install ${BLUE}brew${NC} if it does not exist"

if ! command -v brew >/dev/null 2>&1; then
    echo "No brew detected"
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# General macOS packages.
echo -e "Installing ${RED}packages${NC}"
echo -e "${BLUE}$OSX_PACKAGES${NC}"
echo -n "continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    echo -e "Installing packages"
    brew install $OSX_PACKAGES
fi

# Java.
echo -e "Installing ${RED}Java${NC}"
echo -n "continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    brew install --cask java
fi

exit 0
