# Nordine Home Server

A small self-hosted infrastructure project that turns an old laptop into a
local home server using Ubuntu, rootless Docker, Docker Compose, Caddy, and a
few automation scripts.

The goal of this repository is to keep the server setup reproducible and easy
to review. It documents both the machine bootstrap process and the application
stack that runs after the host is prepared.

## Overview

The stack is designed for a local network, not for direct internet exposure.
Services are reached by local IP address or by local DNS names configured
outside this repository.

Main components:

- Host bootstrap scripts for Ubuntu-based machines
- Rootless Docker for running services without the system Docker daemon
- Docker Compose for service orchestration
- Caddy as the internal reverse proxy and static web server
- File Browser for local file access
- Kanboard for local project boards
- Medical Manager backend, frontend, and Postgres database

DNS and hostname resolution are intentionally left outside the repository. They
can be handled by a router, a local DNS server, or client-side hosts files.

## Target Hardware

The current target machine is an old Acer Aspire A315-21G laptop repurposed as
a small home server.

- CPU: AMD A9-9420 with integrated Radeon graphics
- Memory: 8 GiB DDR4 RAM
- Storage: 256 GB SATA SSD

## Architecture

`docker-compose.yaml` defines the long-running services:

- `caddy`: reverse proxy and static web server
- `filebrowser`: browser-based file manager
- `kanboard`: local Kanban board
- `medical-manager-backend`: backend built from
  `https://github.com/nordine-abde/medical-manager.git#main:backend`
- `medical-manager-postgres`: Postgres database for Medical Manager

The Caddy image also builds the Medical Manager frontend from
`https://github.com/nordine-abde/medical-manager.git#main:frontend` and serves
it as static files.

Routing:

- `${REDIRECT_SCHEME}://${DOMAIN}` serves the landing page
- `/filebrowser` redirects to `filebrowser.${DOMAIN}`
- `/kanboard` redirects to `kanboard.${DOMAIN}`
- `/medical-manager` redirects to `medical-manager.${DOMAIN}`
- `kanboard.${DOMAIN}` proxies to the Kanboard container
- `medical-manager.${DOMAIN}/api/*` proxies to the backend container

## Host Setup

The full host bootstrap is handled by:

```bash
bash full_setup.sh
```

This script is intended for a fresh Ubuntu machine. It prompts before making
system-level changes. To skip confirmations:

```bash
bash full_setup.sh --force
```

`full_setup.sh` runs these steps in order:

1. `install_docker.sh`
2. `make_docker_rootless.sh`
3. `allow_privileged_ports_to_rootless_docker.sh`
4. `resize_main_disk.sh`
5. `configure_firewall.sh`

### Bootstrap scripts

`install_docker.sh` adds Docker's official Ubuntu APT repository and installs
Docker Engine, Buildx, and the Compose plugin.

`make_docker_rootless.sh` installs `uidmap`, runs Docker's rootless setup tool,
and disables the system Docker service and socket.

`allow_privileged_ports_to_rootless_docker.sh` grants
`cap_net_bind_service` to `rootlesskit` so rootless Docker can bind ports `80`
and `443`.

`resize_main_disk.sh` extends `/dev/mapper/ubuntu--vg-ubuntu--lv` to use all
free space in the volume group, then resizes the filesystem. This is specific to
the current Ubuntu LVM layout and should be reviewed before reuse.

`configure_firewall.sh` rebuilds IPv4 and IPv6 filter rules from scratch. It
keeps inbound access limited to established connections, loopback, ICMP, SSH,
HTTP, and HTTPS, then persists the rules with `iptables-persistent`.

## Manual Host Configuration

### Lid behavior

Because the host is a laptop, `systemd-logind` should be configured so the
machine keeps running when the lid is closed.

Edit:

```bash
sudo nano /etc/systemd/logind.conf
```

Set:

```ini
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
LidSwitchIgnoreInhibited=no
```

Apply the change by restarting `systemd-logind` or rebooting:

```bash
sudo systemctl restart systemd-logind
```

```bash
sudo reboot
```

### Remote administration

SSH access should be configured separately so the server can be administered
from another computer on the local network. Either key-based or password-based
authentication can be used depending on the environment.

## Environment

Create a local `.env` file:

```bash
cp .env-example .env
```

Important values:

- `DOMAIN`: local base domain, for example `home.local`
- `REDIRECT_SCHEME`: `http` or `https`
- `CADDY_DATA_FOLDER`: persistent Caddy data directory
- `CADDY_CONFIG_FOLDER`: persistent Caddy config directory
- `FILE_BROWSER_SRV_FOLDER`: files exposed through File Browser
- `FILE_BROWSER_DATABASE_FOLDER`: File Browser database directory
- `FILE_BROWSER_CONFIG_FOLDER`: File Browser config directory
- `MEDICAL_MANAGER_BETTER_AUTH_URL`: Medical Manager auth URL
- `MEDICAL_MANAGER_BETTER_AUTH_SECRET`: application secret
- `MEDICAL_MANAGER_POSTGRES_PASSWORD`: Postgres password
- `MEDICAL_MANAGER_POSTGRES_DATA_FOLDER`: Postgres data directory
- `MEDICAL_MANAGER_DOCUMENTS_FOLDER`: uploaded documents directory
- `MEDICAL_MANAGER_TELEGRAM_BOT_TOKEN`: optional Telegram bot token
- `LOG_LEVEL`: service log level

Compose is configured to fail fast when required Medical Manager secrets are
missing.

## Running The Stack

Validate the resolved Compose configuration:

```bash
docker compose config
```

Start services:

```bash
docker compose up -d
```

Check status:

```bash
docker compose ps
```

Follow logs:

```bash
docker compose logs -f
```

Stop services:

```bash
docker compose down
```

## Validation

Shell scripts can be checked with:

```bash
bash -n full_setup.sh
bash -n resize_main_disk.sh
bash -n configure_firewall.sh
bash -n utils/generate_ed25519_ssh_key.sh
```

Compose and Caddy-related changes should be validated with:

```bash
docker compose config
```

## Security Notes

This repository is designed for a local-only home server. It does not include
public exposure, TLS automation for an internet-facing domain, VPN setup, or
dynamic DNS configuration.

Medical Manager is a self-built prototype (entirely vibe coded) application used to track family
medical information. It has not yet gone through a dedicated security review,
so it should be treated as experimental software and used carefully. Do not
expose it to the internet.
