#!/bin/sh

echo "› Checking on oh-my-zsh"

if [[ ! -d ~/.oh-my-zsh ]]; 
then
    git clone https://github.com/dnguyen85/oh-my-zsh ~/.oh-my-zsh
fi
