# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Use vim keybindings and reduce delay when changing modes
bindkey -v
export KEYTIMEOUT=1

# Should be called before compinit
zmodload zsh/complist
zmodload zsh/zprof

## -- Setopt
setopt histignorealldups sharehistory appendhistory histfindnodups histignorespace
setopt GLOB_COMPLETE        # Show autocompletion menu with globs
setopt MENU_COMPLETE        # Automatically highlight first element of completion menu
setopt AUTO_LIST            # Automatically list choices on ambiguous completion.
setopt COMPLETE_IN_WORD     # Complete from both ends of a word.
setopt autocd               # Automatically cd into typed directory.
setopt interactive_comments
stty -ixon                  # Disable ctrl+s to freeze terminal

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=4096
SAVEHIST=16384
HISTFILE=$HOME/.cache/zsh/.zsh_history

# Use modern completion system
autoload -Uz compinit; compinit
_comp_options+=(globdots) # With hidden files

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "~/.cache/zsh/zcompcache"
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
#zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

## -- Aliases
alias vim="nvim"
alias ls='ls -F --color=auto'
alias df='df -h'               # human-readable sizes
alias free='free -m'           # show sizes in MB
alias grep='grep --color=auto' # colorize output (good for log files)
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# Merge Xresources
alias merge='xrdb -merge ~/.Xresources'

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# gpg encryption
# verify signature for isos
alias gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
# receive the key of a developer
alias gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"

# change your default USER shell
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Log out and log back in for change to take effect.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Log out and log back in for change to take effect.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Log out and log back in for change to take effect.'"

## -- Functions

# Show a different cursor depending on the current mode (visual or insert)
cursor_mode() {
    # See https://ttssh2.osdn.jp/manual/4/en/usage/tips/vim.html for cursor shapes
    cursor_block='\e[2 q'
    cursor_beam='\e[6 q'

    function zle-keymap-select {
        if [[ ${KEYMAP} == vicmd ]] ||
            [[ $1 = 'block' ]]; then
            echo -ne $cursor_block
        elif [[ ${KEYMAP} == main ]] ||
            [[ ${KEYMAP} == viins ]] ||
            [[ ${KEYMAP} = '' ]] ||
            [[ $1 = 'beam' ]]; then
            echo -ne $cursor_beam
        fi
    }

    zle-line-init() {
        echo -ne $cursor_beam
    }

    zle -N zle-keymap-select
    zle -N zle-line-init
}

cursor_mode

# Text objects, similar to ci', to change what is inside single quotes
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  bindkey -M $km -- '-' vi-up-line-or-history
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km $c select-bracketed
  done
done

## -- keybindings
bindkey '^E' autosuggest-accept
bindkey -s '^F' "tmux-sessionizer.sh\n"
bindkey -s '^[l' "ls\n"
# Backspace to not change behavior after changing vi modes
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
# Naviaget history and selection with vim motions
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
# A command can be edited in $EDITOR after typing 'v' in visual mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Only these are useful, the rest are still pending revision
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^N" down-line-or-history
bindkey "^P" up-line-or-history
bindkey "^U" kill-whole-line
bindkey "^['" quote-line

## -- Plugins
source "$ZDOTDIR/zsh-functions"
plug "zsh-autosuggestions"
plug "zsh-syntax-highlighting"
plug "zsh-completions"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=7"
eval "$(starship init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
