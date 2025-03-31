export WORKON_HOME=~/python_envs
export PYTHONPATH=~/.dotfiles/python:~/.software/komodo-python-dbgp/pythonlib:$PYTHONPATH
export PYTHONBREAKPOINT=ipdb.set_trace
#  export PATH=~/python_envs/3.8.3/bin:$PATH

# Pyenv

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Load pyenv-virtualenv automatically 
eval "$(pyenv virtualenv-init -)"

# extra configs set in .localrc

