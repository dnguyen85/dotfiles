# Do not load default rc.conf from global
export RANGER_LOAD_DEFAULT_RF=FALSE

# Alias
alias ra="PYTHONPATH=/usr/local/lib/python3.10/site-packages TERM=screen-256color ranger --confdir=$HOME/.ranger"
