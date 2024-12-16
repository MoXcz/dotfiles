#!/usr/bin/env bash

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# fd
sudo apt install fd-find
ln -s "$(which fdfind)" ~/.local/bin/fd

# starship
curl -sS https://starship.rs/install.sh | sh

# Rust
curl https://sh.rustup.rs -sSf | sh
