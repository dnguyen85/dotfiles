export WORKON_HOME=~/python_envs
export PYTHONPATH=~/.dotfiles/python:~/.software/komodo-python-dbgp/pythonlib:$PYTHONPATH
export PYTHONBREAKPOINT=ipdb.set_trace
#  export PATH=~/python_envs/3.8.3/bin:$PATH

# Pyenv
if command -v pyenv &> /dev/null
then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
fi

# extra configs set in .localrc

