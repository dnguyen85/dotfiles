#!/bin/bash

INSTALL_DIR=~/.fzf

echo "› Checking on fzf"

if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone --depth 1 https://github.com/junegunn/fzf.git $INSTALL_DIR
    $INSTALL_DIR/install
fi

