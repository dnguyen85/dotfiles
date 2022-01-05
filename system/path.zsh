if [[ "$OSX" == "1" ]]
then
    # Local
    export PATH="/usr/local/bin:$PATH"
    # coreutils
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
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
    # Python
    export PATH="/usr/local/opt/python/libexec/bin:$PATH"
    # Matlab
    export PATH="/Applications/MATLAB_R2020a.app/bin:$PATH"
    # TexShop
    export PATH="/Applications/Tex/TeXShop.app/Contents/MacOS:/Applications/Tex/BibDesk.app/Contents/MacOS:$PATH"

else
    export PATH="./bin:/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$DOTFILES/bin:$PATH"
    export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"
fi
