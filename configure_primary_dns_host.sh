#!/usr/bin/env bash

set -euo pipefail

if [ "${1:-}" != "--force" ]; then
  echo "This script will free host port 53 for Docker by disabling the systemd-resolved DNS stub listener."
  echo "It keeps systemd-resolved running and repoints /etc/resolv.conf to the upstream resolver list."
  read -r -p "Continue? [y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 1
  fi
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is required on the target host."
  exit 1
fi

if [ ! -d /etc/systemd ]; then
  echo "This script is intended for systemd-based Linux hosts."
  exit 1
fi

sudo mkdir -p /etc/systemd/resolved.conf.d

sudo tee /etc/systemd/resolved.conf.d/10-disable-stub-listener.conf >/dev/null <<'EOF'
[Resolve]
DNSStubListener=no
EOF

sudo systemctl restart systemd-resolved

if [ -e /run/systemd/resolve/resolv.conf ]; then
  sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
else
  echo "/run/systemd/resolve/resolv.conf was not found after restarting systemd-resolved."
  echo "Check systemd-resolved status before continuing."
  exit 1
fi

echo
echo "Host DNS stub listener disabled."
echo "Port 53 should now be available for Docker if no other DNS service is bound."
echo
echo "Check current port 53 listeners:"
echo "  sudo ss -ltnup '( sport = :53 )'"
echo
echo "If another DNS daemon is still listening, stop or reconfigure it before starting Docker Compose."
echo "Make sure UPSTREAM_DNS_1 is not this same server to avoid a forwarding loop."
echo
echo "Next steps:"
echo "  1. Set UPSTREAM_DNS_1 in your .env, for example 10.110.211.133"
echo "  2. Start the stack with docker compose up -d"
echo "  3. Configure your router or DHCP server to hand out this server IP as the primary DNS"
