bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

export TEXINPUTS=.:~/math/tex//:
alias gvim='gvim --servername xdvi'

export PYTHONPATH=$PYTHONPATH:~
export PATH=~/.local/bin:~/bin:$PATH
export TERM=xterm-256color
export PAGER="less -S"

# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups  
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
