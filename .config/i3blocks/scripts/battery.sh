#!/usr/bin/env bash

STATUS=$(cat /sys/class/power_supply/BAT0/status)
PERCENT=$(cat /sys/class/power_supply/BAT0/capacity)
echo "$STATUS $PERCENT%"
