#!/bin/bash

INSTALL_DIR=~/.software/ranger

echo "› Checking on ranger"

if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/ranger/ranger $INSTALL_DIR
    sudo make -C $INSTALL_DIR install 
fi

