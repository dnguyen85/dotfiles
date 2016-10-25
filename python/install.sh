#!/bin/bash

INSTALL_DIR=~/.software/komodo-python-dbgp

echo "› Checking on python, pip, virtualenv, and PyDBGp"

# Check if virtualenv exists
if ! hash virtualenv 2>/dev/null; then
    # Check if pip exist
    if hash pip 2>/dev/null; then
        sudo -H pip install virtualenv
        sudo -H pip install virtualenvwrapper
    else
        curl -O http://peak.telecommunity.com/dist/ez_setup.py
        sudo python ez_setup.py
        sudo easy_install pip
        sudo -H pip install virtualenv
        sudo -H pip install virtualenvwrapper
    fi
fi

# Check if PyDBGp exists
if [[ ! -d $INSTALL_DIR ]]; then
    mkdir -p $INSTALL_DIR
    git clone https://github.com/dnguyen85/komodo-python-dbgp $INSTALL_DIR
fi
