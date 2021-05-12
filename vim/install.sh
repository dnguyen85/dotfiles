#!/bin/bash

if [[ ! -d ~/.vim ]];
then
    git clone --recursive https://github.com/dnguyen85/vim ~/.vim
fi

if [[ ! -d ~/.config/nvim ]];
then
    echo "Setting up nvim init file\n"
    mkdir -p ~/.config/nvim
    ln -s ~/.dotfiles/vim/nvimrc_setup ~/.config/nvim/init.vim
    ln -s ~/.dotfiles/vim/ginit.vim ~/.config/nvim/ginit.vim
fi
