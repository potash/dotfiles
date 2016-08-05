source .bashrc

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

export TEXINPUTS=:.:~/math/tex
alias gvim='gvim --servername xdvi'

export PYTHONPATH=$PYTHONPATH:~
export PATH=~/bin:$PATH
export TERM=xterm-256color
export PAGER="less -S"
