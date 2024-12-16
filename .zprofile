# If not running interactively, don't do anything
[[ $- != *i* ]] && return

## -- XDG
if [ -z "$XDG_CONFIG_HOME" ] ; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi
if [ -z "$XDG_DATA_HOME" ] ; then
    export XDG_DATA_HOME="$HOME/.local/share"
fi
if [ -z "$XDG_CACHE_HOME" ] ; then
    export XDG_CACHE_HOME="$HOME/.cache"
fi

## -- Environment Variables
export TERM="xterm-256color"
export EDITOR="nvim"
export VISUAL="nvim"
export MANPAGER="nvim +Man!"

## -- Path
if [ -d "$HOME/bin" ] ;
  then PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ;
  then PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.fzf/bin" ] ;
  then PATH="$HOME/.fzf/bin:$PATH"
fi

if [ -d "$HOME/.cargo/bin" ] ;
  then PATH="$HOME/.cargo/bin:$PATH"
fi

if [ -d "$HOME/go/bin" ] ;
  then PATH="$PATH:$HOME/go/bin"
fi

if [ -d "/usr/local/go/bin" ] ;
  then PATH="$PATH:/usr/local/go/bin"
fi

export ZDOTDIR=$HOME/.config/zsh

if [ -z "$ZSH_COMPDUMP" ] ; then
    export ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump-$HOST"
fi

