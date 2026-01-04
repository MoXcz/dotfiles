#!/usr/bin/env bash

IFACE=$(iw dev | awk '$1=="Interface"{print $2}')

if [ -z "$IFACE" ]; then
    echo "󰤮 Disconnected"
    exit 0
fi

if ! ip link show "$IFACE" | grep -q "UP"; then
    echo "󰤮 Disconnected"
    exit 0
fi

LINK_INFO=$(iw dev "$IFACE" link)

if echo "$LINK_INFO" | grep -q "Not connected"; then
    ICON="󰤮"
    SSID="Disconnected"
    SPEED=""
else
    SSID=$(echo "$LINK_INFO" | awk -F': ' '/SSID/ {print $2}')
    SIGNAL_DBM=$(echo "$LINK_INFO" | awk '/signal/ {print $2}')
    SIGNAL=$(( (SIGNAL_DBM + 90) * 100 / 60 ))
    SIGNAL=$(( SIGNAL < 0 ? 0 : SIGNAL > 100 ? 100 : SIGNAL ))

    if [ "$SIGNAL" -ge 80 ]; then
        ICON="󰤯"
    elif [ "$SIGNAL" -ge 60 ]; then
        ICON="󰤟"
    elif [ "$SIGNAL" -ge 40 ]; then
        ICON="󰤢"
    elif [ "$SIGNAL" -ge 20 ]; then
        ICON="󰤥"
    else
        ICON="󰤨"
    fi

    RX1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    sleep 1
    RX2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

    RX_SPEED=$(( (RX2 - RX1) / 1024 ))
    TX_SPEED=$(( (TX2 - TX1) / 1024 ))

    SPEED="↓${RX_SPEED}KB/s ↑${TX_SPEED}KB/s"
fi

echo "$ICON $SSID $SPEED"

case "$BLOCK_BUTTON" in
    1) xdg-terminal-exec impala ;;
esac
