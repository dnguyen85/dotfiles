#!/bin/bash

# Note: needs libncurses5-dev lib

INSTALL_DIR=~/.software/tig
DOTFILES=~/.dotfiles

echo "› Checking on tig"

if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/jonas/tig $INSTALL_DIR
    cd $INSTALL_DIR
    make prefix=$DOTFILES
    make install prefix=$DOTFILES
fi
