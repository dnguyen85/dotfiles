# Load the oh-my-zsh's library
antigen use oh-my-zsh

# Configs from default zsh libs (oh-my-zsh)
antigen theme robbyrussell

# List of other antigen zsh plugins
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-completions src
antigen bundle scheibler/khard misc/zsh
antigen bundle pimutils/khal misc
antigen bundle anntzer/zsh-pandoc-completion --branch=autocomplete-filenames

# Apply
antigen apply
