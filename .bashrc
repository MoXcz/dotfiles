# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export EDITOR='nvim'
export MANPAGER="nvim +Man!"
set -o vi
bind -m vi-command 'Control-l: clear-screen'
bind -m vi-insert 'Control-l: clear-screen'
export GREP_OPTIONS=' —color=auto'

# Configure less:
#   F: automatically exit if the entire file can be displayed in first screen.
#   I: case-insensitive search.
#   R: Show ANSI colors.
#   S: Truncate long lines.
#   X: Prevent clearing the screen when exiting.
# See: https://relentlesscoding.com/2019/01/06/make-less-options-permanent-or-the-missing-lessrc/
export LESS="FIRSX"

# Make less more friendly for non-text input files.
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"


# Don't put duplicate lines or lines starting with space in the history.
export HISTCONTROL=ignorespace:ignoredups;
HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=4096
HISTFILESIZE=16384

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Make less more friendly for non-text input files.
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

## Program
# ------------------------------------------------------------------------------
. "$HOME/.cargo/env" # rust

eval "$(starship init bash)"

# if [ -f "/home/mocos/miniconda3/etc/profile.d/conda.sh" ]; then
#     . "/home/mocos/miniconda3/etc/profile.d/conda.sh"
# else
#     export path="/home/mocos/miniconda3/bin:$path"
# fi

## For n node version manager
export n_prefix="$HOME/n"; [[ :$path: == *":$n_prefix/bin:"* ]] || path+=":$n_prefix/bin"

## Shopt
# ------------------------------------------------------------------------------
shopt -s checkwinsize # check window size after each command
shopt -s nocaseglob # match filenames in a case-insensitive fashion
shopt -s no_empty_cmd_completion # Avoid autocomplete on an empty line
shopt -s histappend # Append to the history file, don't overwrite it
shopt -s cdspell # correct cd mispell
shopt -s expand_aliases
shopt -s autocd

## Environment Variables
# ------------------------------------------------------------------------------
if [ -z "$XDG_CONFIG_HOME" ] ; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi
if [ -z "$XDG_DATA_HOME" ] ; then
    export XDG_DATA_HOME="$HOME/.local/share"
fi
if [ -z "$XDG_CACHE_HOME" ] ; then
    export XDG_CACHE_HOME="$HOME/.cache"
fi

## Paths
# ------------------------------------------------------------------------------
if [ -d "$HOME/bin" ] ;
  then PATH="$PATH:$HOME/bin"
fi
if [ -d "$HOME/.local/bin" ] ;
  then PATH="$PATH:$HOME/.local/bin"
fi
if [ -d "$HOME/Apps" ] ;
  then PATH="$PATH:$HOME/Apps"
fi
[ -f "$HOME/.fzf.bash" ] && source "$HOME/.fzf.bash"

PATH="$(echo "$PATH" | awk 'BEGIN{RS=":";}
{sub(sprintf("%c$",10),"");if(A[$0]){}else{A[$0]=1;
printf(((NR==1)?"":":")$0)}}')";
export PATH

## Aliases
# ------------------------------------------------------------------------------
# Use -std=c++11 to add an standard. Use [11, 14, 17, 20, 23] 
alias g+++='g++ -Wall -Weffc++ -Wextra -Wconversion -Wsign-conversion -pedantic-errors -Werror -o' 
alias vim='nvim'
alias vifzf='fd -t file --hidden --exclude .git --exclude .github --search-path . | fzf --print0 --reverse --border=rounded --height 20 | xargs -r0 nvim'
alias fzp='fzf --preview="batcat --color=always {}"'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='ls -F --color=auto'
alias grep='grep --color=auto'
alias df='df -h'
alias free='free -m'
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Log out and log back in for change to take effect.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Log out and log back in for change to take effect.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Log out and log back in for change to take effect.'"
