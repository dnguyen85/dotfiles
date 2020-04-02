#!/bin/bash

INSTALL_DIR=~/.software/gnome-terminal-solarized

echo "› Checking on gnome-terminal-solarized"

if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/aruhier/gnome-terminal-colors-solarized $INSTALL_DIR
    cd $INSTALL_DIR
    if hash gnome-terminal 2>/dev/null; then
        ./install.sh 
    fi 
fi

