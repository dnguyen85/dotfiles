if [[ "$OSX" == "1" ]]
then
    # coreutils
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$DOTFILES/bin:$PATH"
    export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
    # find
    export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
    export MANPATH="/usr/local/opt/findutils/libexec/gnuman:$MANPATH"
    # grep
    export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
    export MANPATH="/usr/local/opt/grep/libexec/gnuman:$MANPATH"
    # sed
    export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
    export MANPATH="/usr/local/opt/gnu-sed/libexec/gnuman:$MANPATH"
    # tar
    export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
    export MANPATH="/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH"
    # Matlab
    export PATH="/Applications/MATLAB_R2020a.app/bin:$PATH"
else
    export PATH="./bin:/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$DOTFILES/bin:$PATH"
    export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"
fi
