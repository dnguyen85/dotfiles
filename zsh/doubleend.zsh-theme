local ret_status="%(?:%{$fg_bold[yellow]%}➤➤ :%{$fg_bold[red]%}➤➤ %s)"
PROMPT='${ret_status}%{$fg_bold[magenta]%}%m:%{$fg_bold[yellow]%}%~$(git_prompt_info)%{$fg_bold[yellow]%}$ % %{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX=" (%{$fg_bold[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%}✗%{$fg_bold[yellow]%})"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[yellow]%})"
