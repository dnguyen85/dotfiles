#!/bin/bash

INSTALL_DIR=~/.software/mutt-colors-solarized

echo "› Checking on mutt-colors-solarized"

if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/altercation/mutt-colors-solarized $INSTALL_DIR
fi

