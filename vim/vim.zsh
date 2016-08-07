# Default editor
export EDITOR=vim

# Stardict and sdcv
if [[ -f "${HOME}"/.vim/bundle/vim-stardict/bindings/zsh/stardict.zsh ]]; then
    source "${HOME}"/.vim/bundle/vim-stardict/bindings/zsh/stardict.zsh
fi
alias whatis="stardict"
alias whatvim="vstardict"
