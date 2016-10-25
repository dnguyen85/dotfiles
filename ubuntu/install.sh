#!/bin/bash

# Run only for ubuntu
if [ "$(uname -s)" == "Linux" ]
then
    echo "› Installing Ubuntu packages"

    # add repos
    # sudo add-apt-repository -y ppa:webupd8team/sublime-text-3

    # basic update
    sudo apt-get -qq -y --force-yes update
    sudo apt-get -qq -y --force-yes upgrade

    # install apps
    sudo apt-get -qq -y install \
        build-essential libncurses5-dev exuberant-ctags 
fi
