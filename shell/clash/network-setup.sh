#!/bin/bash

set -e

case "$1" in
start)
    echo "[Network Setup] Applying ip rules and iptables..."

    # IP rules
    ip rule add fwmark 1 table 100 || true
    ip route add local 0.0.0.0/0 dev lo table 100 || true

    # IPTABLES
    iptables -t mangle -N CLASH || true
    iptables -t mangle -A CLASH -d 0.0.0.0/8 -j RETURN || true
    iptables -t mangle -A CLASH -d 127.0.0.0/8 -j RETURN || true
    iptables -t mangle -A CLASH -d 192.168.1.0/24 -j RETURN || true
    iptables -t mangle -A CLASH -d 192.168.20.0/23 -j RETURN || true
    iptables -t mangle -A CLASH -d 192.168.48.0/21 -j RETURN || true
    iptables -t mangle -A CLASH -d 192.168.254.0/24 -j RETURN || true
    iptables -t mangle -A CLASH -p tcp -j TPROXY --tproxy-mark 1 --on-port 7893 || true
    iptables -t mangle -A CLASH -p udp -j TPROXY --tproxy-mark 1 --on-port 7893 || true
    iptables -t mangle -A PREROUTING -j CLASH || true

    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to 1053 || true

    # “源地址伪装”（MASQUERADE） 从 Linux 机器出来的流量伪装成 Linux 自己的 IP。
    iptables -t nat -A POSTROUTING -o enp0s31f6 -j MASQUERADE || true
    # 允许 wlxc83a3558499c 来的流量 转发到 enp0s31f6
    iptables -A FORWARD -i wlxc83a3558499c -o enp0s31f6 -j ACCEPT || true
    # 允许 enp0s31f6 返回来的流量 转发回 wlxc83a3558499c
    iptables -A FORWARD -i enp0s31f6 -o wlxc83a3558499c -m state --state ESTABLISHED,RELATED -j ACCEPT || true

    ;;
stop)
    echo "[Network Setup] Cleaning up ip rules and iptables..."

    # IP rules
    ip rule del fwmark 1 table 100 || true
    ip route del local 0.0.0.0/0 dev lo table 100 || true

    # IPTABLES
    iptables -D FORWARD -i wlxc83a3558499c -o enp0s31f6 -j ACCEPT || true
    iptables -D FORWARD -i enp0s31f6 -o wlxc83a3558499c -m state --state ESTABLISHED,RELATED -j ACCEPT || true
    iptables -t nat -D POSTROUTING -o enp0s31f6 -j MASQUERADE || true

    iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to 1053 || true

    iptables -t mangle -D PREROUTING -j CLASH || true

    iptables -t mangle -F CLASH || true
    iptables -t mangle -X CLASH || true
    
    ;;
*)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
