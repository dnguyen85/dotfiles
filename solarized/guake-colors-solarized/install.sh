#!/bin/bash

INSTALL_DIR=~/.software/guake-colors-solarized

echo "› Checking on guake-colors-solarized"

if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/coolwanglu/guake-colors-solarized $INSTALL_DIR
fi

