#!/usr/bin/env bash

CPU_USAGE=$((100-$(vmstat 1 2 | tail -1 | awk '{print $15}')))
CPU_TEMP=$(awk '{printf "%.0f", $1/1000}' /sys/class/hwmon/hwmon1/temp1_input)

[ -z "$CPU_USAGE" ] && CPU_USAGE="N/A"
[ -z "$CPU_TEMP" ] && CPU_TEMP="N/A"

echo "CPU: ${CPU_USAGE}% at ${CPU_TEMP} C"
