#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scripts=$(find "$script_dir/runs" -maxdepth 1 -mindepth 1 -executable -type f)

log() {
  echo Running: "$@"
}

menu_items="Run All\nTest Run"
for script in $scripts; do
    menu_items="$menu_items\n$(basename "$script")"
done

choice=$(echo -e "$menu_items" | bemenu -b -l 5 -p "Choose a script to run:")

if [[ -z "$choice" ]]; then
    exit 0
fi

run_cmd() {
  for script in $scripts; do
    echo Running: "$script"
    "$script"
    echo "$script"
  done
}

test_run() {
  for script in $scripts; do
    log "$script"
  done
}

case "$choice" in
    "Run All")
        run_cmd ;;
    "Test Run")
        test_run ;;
    *)
        selected_script="$script_dir/runs/$choice"
        if [[ -x "$selected_script" ]]; then
            "$selected_script"
        else
            log "Error: Selected script is not executable."
        fi
        ;;
esac
