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

path() {
  if [[ "$PATH" != *"$1"* ]]; then
    export PATH=$PATH:$1
  fi
}

## -- Environment Variables
export TERM="xterm-256color"
export EDITOR="nvim"
export VISUAL="nvim"
export MANPAGER="nvim +Man!"

## -- Path
path $HOME/.local/bin
path $HOME/.fzf/bin
path $HOME/.cargo/bin
path $HOME/go/bin
path /usr/local/go/bin
path "$HOME"/.lua/src
path "$HOME"/scripts
path "$HOME"/.local/n/bin
path /usr/games
path "$HOME"/.rbenv/shims
path "$HOME"/.rbenv/bin

export ZDOTDIR=$HOME/.config/zsh

if [ -z "$ZSH_COMPDUMP" ] ; then
    export ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump-$HOST"
fi

