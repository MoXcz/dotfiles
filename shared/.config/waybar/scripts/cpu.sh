#!/usr/bin/env bash

CPU_USAGE=$((100 - $(vmstat 1 2 | tail -1 | awk '{print $15}')))

# find CPU sensor by driver name: coretemp (Intel), k10temp / zenpower (AMD).
CPU_TEMP=""
for dir in /sys/class/hwmon/hwmon*; do
  case "$(cat "$dir/name" 2>/dev/null)" in
  coretemp | k10temp | zenpower)
    [[ -r $dir/temp1_input ]] && CPU_TEMP=$(awk '{printf "%.0f", $1/1000}' "$dir/temp1_input")
    break
    ;;
  esac
done

[ -z "$CPU_USAGE" ] && CPU_USAGE="N/A"
[ -z "$CPU_TEMP" ] && CPU_TEMP="N/A"

echo "| CPU: ${CPU_USAGE}% at ${CPU_TEMP} C"
