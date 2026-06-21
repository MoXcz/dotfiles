#!/usr/bin/env bash

set -e

# Colors for output
C_MAIN='\033[38;2;202;169;224m'
C_GREEN='\033[38;2;166;209;137m'
C_RED='\033[38;2;231;130;132m'
C_YELLOW='\033[38;2;229;200;144m'
C_RESET='\033[0m'

# Defaults
SETUP_COMPONENTS=""
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --setup | -s)
    SETUP_COMPONENTS="$2"
    shift 2
    ;;
  --dry-run | -d)
    DRY_RUN=true
    shift
    ;;
  --help | -h)
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --setup,-s COMPONENTS   Comma-separated list of components to install"
    echo "                           Available: yay, tools, qylock, wifi-driver"
    echo "  --dry-run,-d            Show what would be installed without installing"
    echo "  --help,-h               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --setup yay,tools"
    echo "  $0 --setup qylock"
    echo "  $0 --setup yay,tools,qylock,wifi-driver"
    exit 0
    ;;
  *)
    echo -e "${C_RED}Unknown option: $1${C_RESET}"
    exit 1
    ;;
  esac
done

# Prompt for components if not provided
if [ -z "$SETUP_COMPONENTS" ]; then
  echo -e "${C_MAIN}Available installation components:${C_RESET}"
  echo "  1) yay              - AUR package manager"
  echo "  2) tools            - Development tools (zsh, tree-sitter, linux-headers, net-tools, unzip)"
  echo "  3) qylock           - Quickshell lockscreen setup"
  echo "  4) wifi-driver      - RTL8821CU AC600 Wi-Fi dongle driver"
  echo ""
  echo -e "${C_YELLOW}Enter components to install (comma-separated, e.g., 1,2,3):${C_RESET} "
  read -r COMPONENT_NUMS

  SETUP_COMPONENTS=""
  IFS=',' read -ra NUMS <<<"$COMPONENT_NUMS"
  for num in "${NUMS[@]}"; do
    num=$(echo "$num" | xargs) # Trim whitespace
    case $num in
    1) [[ -z "$SETUP_COMPONENTS" ]] && SETUP_COMPONENTS="yay" || SETUP_COMPONENTS="$SETUP_COMPONENTS,yay" ;;
    2) [[ -z "$SETUP_COMPONENTS" ]] && SETUP_COMPONENTS="tools" || SETUP_COMPONENTS="$SETUP_COMPONENTS,tools" ;;
    3) [[ -z "$SETUP_COMPONENTS" ]] && SETUP_COMPONENTS="qylock" || SETUP_COMPONENTS="$SETUP_COMPONENTS,qylock" ;;
    4) [[ -z "$SETUP_COMPONENTS" ]] && SETUP_COMPONENTS="wifi-driver" || SETUP_COMPONENTS="$SETUP_COMPONENTS,wifi-driver" ;;
    esac
  done
fi

# Helper functions
log_info() {
  echo -e "${C_MAIN}→${C_RESET} $1"
}

log_success() {
  echo -e "${C_GREEN}✔${C_RESET} $1"
}

log_error() {
  echo -e "${C_RED}✘${C_RESET} $1"
}

execute() {
  if [ "$DRY_RUN" = true ]; then
    echo -e "${C_YELLOW}[DRY RUN]${C_RESET} $1"
  else
    eval "$1"
  fi
}

# Parse components and install
IFS=',' read -ra COMPONENTS <<<"$SETUP_COMPONENTS"

for component in "${COMPONENTS[@]}"; do
  component=$(echo "$component" | xargs) # Trim whitespace

  case $component in
  yay)
    log_info "Installing yay (AUR package manager)..."

    # Check if yay is already installed
    if command -v yay &>/dev/null; then
      log_success "yay is already installed"
    else
      execute "git clone https://aur.archlinux.org/yay.git /tmp/yay"
      execute "cd /tmp/yay && makepkg -si --noconfirm"
      log_success "yay installed successfully"
    fi
    ;;

  tools)
    log_info "Installing development tools..."

    execute "sudo pacman -S --noconfirm \
        zsh \
        tree-sitter tree-sitter-cli \
        unzip \
        linux-headers \
        net-tools"

    log_success "Development tools installed successfully"
    ;;

  wifi-driver)
    log_info "Installing AC600 Wi-Fi dongle driver (RTL8821CU)..."

    # Verify yay is installed
    if ! command -v yay &>/dev/null; then
      log_error "yay is not installed. Install it first with: $0 --setup yay"
      exit 1
    fi

    # Check if driver is already installed
    if dkms status | grep -q rtl8821cu; then
      log_success "RTL8821CU driver is already installed"
    else
      execute "yay -S --noconfirm rtl8821cu-morrownr-dkms-git"
      log_success "RTL8821CU driver installed successfully"
    fi
    ;;

  qylock)
    log_info "Setting up qylock (Quickshell lockscreen)..."

    # Check if quickshell is installed
    if ! command -v quickshell &>/dev/null; then
      log_error "Quickshell is not installed. Install it first with: yay -S quickshell"
      exit 1
    fi

    # Run the qylock setup script
    QYLOCK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/qylock"
    if [ -f "$QYLOCK_DIR/quickshell.sh" ]; then
      if [ "$DRY_RUN" = false ]; then
        bash "$QYLOCK_DIR/quickshell.sh"
      else
        echo -e "${C_YELLOW}[DRY RUN]${C_RESET} Would run: bash $QYLOCK_DIR/quickshell.sh"
      fi
      log_success "qylock setup completed"
    else
      log_error "qylock setup script not found at $QYLOCK_DIR/quickshell.sh"
      exit 1
    fi
    ;;

  *)
    log_error "Unknown component: $component"
    exit 1
    ;;
  esac
done

echo ""
if [ "$DRY_RUN" = true ]; then
  log_info "Dry run completed. No changes were made."
else
  log_success "All selected components installed successfully!"
fi
