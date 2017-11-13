#!/bin/bash

INSTALL_DIR=~/.software/mintty-colors-solarized

echo "› Checking on mintty-colors-solarized"

if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/karlin/mintty-colors-solarized $INSTALL_DIR
    cd $INSTALL_DIR
    if hash mintty 2>/dev/null; then
        ln -s $INSTALL_DIR/.minttyrc--solarized-dark ~/.minttyrc 
    fi 
fi

