#!/bin/bash

echo "› Checking on python, pip, and virtualenv"

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
