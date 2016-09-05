#!/usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

# Run only for osx
if [ "$(uname -s)" == "Darwin" ]
then
    echo "› Installing powerline fonts for macOS"
    rsync --exclude ".DS_Store" --exclude ".git/" --exclude "install.sh" -av --no-perms $DOTFILES_ROOT/fonts/fonts.symlink/ ~/Library/Fonts/
fi
