#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE_FLAG=""

if [ "${1:-}" = "--force" ]; then
  FORCE_FLAG="--force"
fi

if [ "$FORCE_FLAG" != "--force" ]; then
  echo "Warning: this setup is intended for a fresh Ubuntu machine."
  echo "It will install Docker, reconfigure host DNS behavior, enable rootless Docker,"
  echo "grant privileged port binding to rootless Docker, resize the main disk,"
  echo "and rebuild the firewall rules."
  echo
  read -r -p "Continue with full machine setup? [y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 1
  fi
fi

run_step() {
  local label="$1"
  shift

  echo
  echo "==> $label"
  "$@"
}

cd "$REPO_ROOT"

run_step "Installing Docker and Compose" bash "$REPO_ROOT/install_docker.sh"
run_step "Configuring rootless Docker" bash "$REPO_ROOT/make_docker_rootless.sh"
run_step "Allowing privileged ports for rootless Docker" bash "$REPO_ROOT/allow_privileged_ports_to_rootless_docker.sh"
run_step "Resizing the main disk" bash "$REPO_ROOT/resize_main_disk.sh" ${FORCE_FLAG:+"$FORCE_FLAG"}
run_step "Freeing host port 53 for the DNS container" bash "$REPO_ROOT/configure_primary_dns_host.sh" ${FORCE_FLAG:+"$FORCE_FLAG"}
run_step "Rebuilding the firewall rules" bash "$REPO_ROOT/configure_firewall.sh" ${FORCE_FLAG:+"$FORCE_FLAG"}

echo
echo "Full machine setup completed."
echo
echo "Next steps:"
echo "  1. Copy .env-example to .env"
echo "  2. Set DOMAIN, IP, UPSTREAM_DNS_1, and any path overrides"
echo "  3. Run docker compose config"
echo "  4. Run docker compose up -d"
echo "  5. Point your router or DHCP server to this host as the primary DNS server"
