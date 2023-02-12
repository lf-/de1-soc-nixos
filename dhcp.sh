#!/bin/sh

if [[ $# < 1 ]]; then
    echo "Usage: $0 INTERFACE" >&2
    exit 1
fi

self="$(dirname $0)"
interface=$1

ip link set "$interface" up
ip addr add dev "$interface" 192.168.200.1/24
dnsmasq --no-daemon -i "$interface" \
    --bind-interfaces \
    --except-interface='wlan0' \
    --except-interface='lo' \
    --dhcp-range=192.168.200.2,192.168.200.100,255.255.255.0 \
    --listen-address=192.168.200.1 \
    --log-dhcp \
    --dhcp-leasefile="$self/dhcp.leases"
