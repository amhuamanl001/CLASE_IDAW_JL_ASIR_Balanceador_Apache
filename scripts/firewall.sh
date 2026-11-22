#!/bin/bash
set -eu

# Cada VM filtra las conexiones que llegan a sus propias interfaces.
case "$1" in
    balanceador)
        reglas='ip daddr 10.0.2.15 tcp dport { 80, 443 } accept'
        ;;
    web1)
        reglas='ip saddr 192.168.57.10 ip daddr 192.168.57.11 tcp dport { 22, 80 } accept'
        ;;
    web2)
        reglas='ip saddr 192.168.57.10 ip daddr 192.168.57.12 tcp dport { 22, 80 } accept'
        ;;
    mysql)
        reglas='ip saddr { 192.168.58.11, 192.168.58.12 } ip daddr 192.168.58.20 tcp dport 3306 accept
        ip saddr 192.168.58.11 ip daddr 192.168.58.20 tcp dport 22 accept'
        ;;
    *)
        exit 2
        ;;
esac

cat > /etc/nftables.conf <<NFT
table inet practica
flush table inet practica

table inet practica {
    chain input {
        type filter hook input priority filter; policy drop;
        iifname "lo" accept
        ct state established,related accept
        ip saddr 10.0.2.2 ip daddr 10.0.2.15 tcp dport 22 accept
        ip protocol udp udp sport 67 udp dport 68 accept
        $reglas
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
    }
}
NFT

nft -c -f /etc/nftables.conf
nft -f /etc/nftables.conf
systemctl enable nftables
