#!/usr/bin/env bash

set -euo pipefail

echo "Warning: this will rebuild the host filter firewall from scratch."
echo "It flushes existing filter rules, sets default policies, and re-adds only the required allow rules."

if [ "${1:-}" != "--force" ]; then
  read -r -p "Continue? [y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 1
  fi
fi

reset_filter_table() {
  local cmd="$1"

  sudo "$cmd" -F
  sudo "$cmd" -X
  sudo "$cmd" -P INPUT DROP
  sudo "$cmd" -P FORWARD DROP
  sudo "$cmd" -P OUTPUT ACCEPT

  sudo "$cmd" -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  sudo "$cmd" -A INPUT -i lo -j ACCEPT
}

reset_filter_table iptables
reset_filter_table ip6tables

sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 21 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 30000:30009 -j ACCEPT

sudo ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
sudo ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo ip6tables -A INPUT -p tcp --dport 21 -j ACCEPT
sudo ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo ip6tables -A INPUT -p tcp --dport 30000:30009 -j ACCEPT

if ! dpkg -s iptables-persistent >/dev/null 2>&1; then
  sudo apt update
  sudo env DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent
fi

sudo mkdir -p /etc/iptables
sudo sh -c 'iptables-save > /etc/iptables/rules.v4'
sudo sh -c 'ip6tables-save > /etc/iptables/rules.v6'

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable netfilter-persistent >/dev/null 2>&1 || true
  sudo systemctl restart netfilter-persistent
fi

echo "Firewall filter rules rebuilt from scratch and saved persistently."
