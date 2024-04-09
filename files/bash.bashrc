export PATH="${PATH}:/usr/games:${HOME}/bin:${HOME}/.local/bin"

# lang
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# bash tweaks
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export VISUAL="$(which vim)"
export EDITOR="$(which vim)"
export HISTTIMEFORMAT="%F %T "
export HISTFILESIZE=99999
export HISTSIZE=99999
export HISTCONTROL=ignoredups

# less tweaks
scrtitle='\[\033k\033\\\]'  # ESC k ESC \ for titles in screen. advanced magic here.
export LESS='-asrRix8'
export LESSCHARSET='utf-8'
export LESS_TERMCAP_mb=$'\E[01;31m'         # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;208m'   # begin bold
export LESS_TERMCAP_me=$'\E[0m'             # end mode
export LESS_TERMCAP_se=$'\E[0m'             # end standout-mode
export LESS_TERMCAP_so=$'\E[38;07;246m'     # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'             # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;111m'   # begin underline

# Colored Shell Prompt
if [ $UID -eq 0 ] ; then
  export PS1='\[\e[1;31m\]\u@\h \[\e[1;33m\]\w\[\e[0m\]\n\$ '
else
  export PS1='\[\e[1;32m\]\u@\h \[\e[1;33m\]\w\[\e[0m\]\n\$ '
fi

# aliases
alias monitor='sudo tail -vf /var/log/syslog'
alias ls='ls -Fa'
alias ll='ls -FGalhp'
alias grep='grep --color=auto'
alias vi=vim
alias k=kubectl
alias k9s='k9s -n dev'
