# nodenv
if command -v nodeenv
then
    export NODENV_ROOT="$HOME/.nodenv"
    export PATH="$HOME/.nodenv/bin:$PATH"
    eval "$(nodenv init -)"
fi

