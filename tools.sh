git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# driver for ac600 Wi-Fi dongle
# yay -S rtl8821cu-morrownr-dkms-git

sudo pacman -S \
  zsh \
  tree-sitter tree-sitter-cli \
  unzip \
  linux-headers \
  net-tools
