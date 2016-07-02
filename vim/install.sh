#!/bin/sh

if [[ ! -d ~/.vim ]];
then
    git clone --recursive https://github.com/dnguyen85/vim ~/.vim
fi
