#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TARGET_DIR="$HOME"
DRY_RUN=false
SHARED_DIR="shared"

for arg in "$@"; do
    case "$arg" in
        --dry-run|-n)
            DRY_RUN=true
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

if ! command -v stow >/dev/null 2>&1; then
    echo "Error: stow is not installed."
    exit 1
fi

if [[ ! -d "$SHARED_DIR" ]]; then
    echo "Error: Shared directory '$SHARED_DIR' not found."
    exit 1
fi

PROFILES=("omarchy" "paradise-lost")

unstow_others() {
    local selected="$1"

    for p in "${PROFILES[@]}"; do
        if [[ "$p" != "$selected" ]] && [[ -d "$p" ]]; then
            echo "Unstowing $p..."
            if $DRY_RUN; then
                stow -D -n -v -t "$TARGET_DIR" "$p"
            else
                stow -D -v -t "$TARGET_DIR" "$p" || true
            fi
        fi
    done
}

stow_shared() {
    echo "Stowing shared config (.config)..."
    if $DRY_RUN; then
        stow -n -v -t "$TARGET_DIR" "$SHARED_DIR"
    else
        stow -v -t "$TARGET_DIR" "$SHARED_DIR"
    fi
}

stow_profile() {
    local profile="$1"

    if [[ ! -d "$profile" ]]; then
        echo "Directory '$profile' not found."
        exit 1
    fi

    echo -e "\nSwitching to profile: $profile\n"

    unstow_others "$profile"
    stow_shared

    echo "Stowing $profile..."
    if $DRY_RUN; then
        stow -n -v -t "$TARGET_DIR" "$profile"
    else
        stow -v -t "$TARGET_DIR" "$profile"
    fi

    echo
    echo "Done."
}

PS3=$'\nSelect a profile to stow: '

options=("omarchy" "paradise-lost" "Quit")

select opt in "${options[@]}"; do
    [[ "$opt" == "Quit" ]] && exit

    if [[ -n "$opt" ]]; then
        stow_profile "$opt"
        break
    else
        echo "Invalid selection."
    fi
done
