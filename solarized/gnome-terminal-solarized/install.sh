#!/bin/bash

INSTALL_DIR=~/.software/gnome-terminal-solarized

echo "› Checking on gnome-terminal-solarized"

if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/Anthony25/gnome-terminal-colors-solarized $INSTALL_DIR
    cd $INSTALL_DIR
    ./install.sh
fi

