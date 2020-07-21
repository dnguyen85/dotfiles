alias ll='ls -hl'
alias la='ls -al'
alias lc='ls -CF'
alias eclipse="eclipse 2>/dev/null"
alias nau="nautilus ."
alias okular="okular 2>/dev/null"
alias gitl="git log-graph"
#  alias git="hub"
alias t="task"
alias tw="task -misc"
alias tm="task +misc"
alias td="task due:today"
alias to="taskopen"
alias gs="git status"
alias gc="git commit"
alias ga="git add"
alias dirdiff="gvim --cmd 'let nodiffchar=1'"
# Foreground imap sync
alias O="offlineimap"
alias o="offlineimap -qf INBOX"
alias m="cd ~/Downloads && mail && cd -"
alias kli="ikhal"
alias kl="khal"
alias kh="khard"
alias v="vdirsyncer sync"
alias os="odrive status"
alias or="orefresh"
#  alias vim="nvim"
alias htop="TERM=screen-256color htop"
alias tig="TERM=screen-256color tig"
alias sles12sub='bsub -q priority -Is -R "select[sles12 && mem>4000] rusage[mem=4000] span[hosts=1]"'
alias tmuxsub='bsub -Is -q interactive -W43200 -n16 -R "select[sles12 && type==LINUX64 && mem>64000] rusage[mem=64000] span[hosts=1]" mux'
alias tmuxsub8='bsub -Is -q interactive -W43200 -n8 -R "select[sles12 && type==LINUX64 && mem>32000] rusage[mem=32000] span[hosts=1]" mux'
alias isub='bsub -Is -q interactive -R "select[sles12 && mem>16000] rusage[mem=16000] span[hosts=1]"'
alias boringdiff='svn diff --diff-cmd=/usr/bin/diff'
alias matlab_cli='Matlab -qc_ver 2020a -nodesktop -nosplash'
