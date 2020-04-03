#!/bin/bash

if [[ ! -d ~/.vim ]];
then
    git clone --recursive https://github.com/dnguyen85/vim ~/.vim
fi

if [[ ! -d ~/.config/nvim ]];
then
    mkdir -p ~/.config/nvim
    ln -s ~/.dotfiles/vim/nvimrc_setup ~/.config/nvim/init.vim
fi
