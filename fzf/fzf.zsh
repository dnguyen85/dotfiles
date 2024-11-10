export FZF_DEFAULT_OPS="--layout=reverse --inline-info --extended"

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# Modified version where you can press
#   - CTRL-O to open with `open` command,
#   - CTRL-E or Enter key to open with the $EDITOR
fo() {
  IFS=$'\n' out=("$(fzf-tmux --query="$1" --exit-0 --expect=ctrl-o,ctrl-e)")
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [ -n "$file" ]; then
    [ "$key" = ctrl-o ] && open "$file" || ${EDITOR:-vim} "$file"
  fi
}

# fuzzy grep open via ag with line number
fg() {
  local file
  local line

  read -r file line <<<"$(ag --nobreak --noheading $@ | fzf -0 -1 | awk -F: '{print $1, $2}')"

  if [[ -n $file ]]
  then
     vim $file +$line
  fi
}

# fuzzy grep on a single file with line number, then open link
fs() {
  local title
  local url

  read -r title url <<<"$(cat $@ | fzf -0 -1 | awk -F' ' '{print $1, $NF}')"

  if [[ -n $title ]]
  then
     open $url
  fi
}


# fuzzy grep on a single file with line number, then copy content to clipboard
fc() {
  local title
  local snippet

  IFS=";" read -r title snippet <<< "$(cat $@ | fzf -0 -1)"

  if [[ -n $title ]]
  then
     lemonade copy $snippet
     echo "Copy snippet \"$title\" to clipboard"
  fi
}

# fh - repeat history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}
