#!/usr/bin/env bash

is_debian_based() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* ]]
  elif command -v apt >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

nvim_curl() {
  local version="${1:-stable}"

  if [[ "$version" != "stable" && "$version" != "nightly" ]]; then
    echo "Invalid version: $version"
    echo "Valid options: stable | nightly"
    return 1
  fi

  echo "Installing Neovim $version"

  if is_debian_based; then
    sudo apt install -y make gcc ripgrep unzip git xclip curl
  fi

  # Now we install nvim
  curl -LO https://github.com/neovim/neovim/releases/download/"$version"/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo mkdir -p /opt/nvim-linux-x86_64
  sudo chmod a+rX /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  rm -i nvim-linux-x86_64.tar.gz

  # make it available in /usr/local/bin, distro installs to /usr/bin
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/
  # From: https://github.com/nvim-lua/kickstart.nvim
}

nvim_build() {
  local download_dir=$HOME/Downloads
  if [ ! -d "$download_dir" ]; then
    echo "$download_dir" does not exist, creating it...
    mkdir download_dir
  fi

  if [ -d "$HOME/Downloads/neovim" ]; then
    echo "Neovim already cloned, downloading..."
  else
    echo "Neovim is not cloned, cloning it..."
    git clone "https://github.com/neovim/neovim.git" "$download_dir"/neovim
  fi

  cd "$download_dir"/neovim || exit
  git fetch
  git checkout stable

  if is_debian_based; then
    sudo apt install cmake gettext lua5.1 liblua5.1-0-dev
  fi

  make CMAKE_BUILD_TYPE=RelWithDebInfo
  sudo make install
}

choice=4
echo "1. curl nvim stable"
echo "2. curl nvim nightly"
echo "3. build nvim stable"
echo -n "Chose one installation method [1, 2, 3]: "

while [ "$choice" -eq 4 ]; do
  read -r choice
  if [ "$choice" -eq 1 ]; then
    nvim_curl stable
  elif [ "$choice" -eq 2 ]; then
    nvim_curl nightly
  elif [ "$choice" -eq 3 ]; then
    nvim_build
  else
    choice=4
    echo "Error! Choose [1, 2, or 3]"
    echo -n "Chose one installation method [1, 2, 3]: "
  fi

done
