#!/usr/bin/env bash

MEM_PERCENT=$(free -b | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

[ -z "$MEM_PERCENT" ] && MEM_PERCENT="N/A"

echo "| RAM: ${MEM_PERCENT}%"
