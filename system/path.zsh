if [[ "$OSX" == "1" ]]
then
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$DOTFILES/bin:$PATH"
    export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
else
    export PATH="./bin:/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$DOTFILES/bin:$PATH"
    export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"
fi
