#!/bin/bash

source $ENVPATH

echo -e "Installing on debian. Use ${BLUE}apt${NC} to Install"

# general server packages
echo -e "Installing ${RED}POSIX packages${NC}"
echo -e "${BLUE}$SERVER_PACKAGES${NC}"
echo -n "continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    sudo apt update
    sudo apt upgrade
    sudo apt install -y $SERVER_PACKAGES
fi

# Java10
echo -e "Installing ${RED}Java${NC}"
echo -n "continue? [y/N] "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    sudo add-apt-repository ppa:linuxuprising/java
    sudo apt update
    sudo apt install oracle-java11-installer-local
fi

exit 0
