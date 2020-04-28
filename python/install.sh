#!/bin/bash

INSTALL_DIR=~/.software/komodo-python-dbgp

echo "› Checking on python, pip, virtualenv, and PyDBGp"

# Check if pip exist
if hash pip3 2>/dev/null; then
    sudo -H pip3 install virtualenvwrapper
fi

# Check if PyDBGp exists
if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/dnguyen85/komodo-python-dbgp $INSTALL_DIR
fi
