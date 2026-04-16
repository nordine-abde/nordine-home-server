# Nordine Home Server

Small home-server setup for running a few personal services behind Caddy with
Docker Compose.

The repository contains two different kinds of automation:

- host setup scripts, intended for a fresh Ubuntu machine
- Docker Compose configuration, used to run the long-lived services

## Warning

Some scripts in this repository make system-level changes and can be
destructive. They install packages, disable the system Docker daemon, configure
rootless Docker, grant extra capabilities, resize the main logical volume, and
replace firewall rules.

Review every script before running it. These scripts are intended for a fresh
machine prepared for this setup, not for an already configured server that you
need to preserve.

## Services

`docker-compose.yaml` currently runs:

- `caddy`: reverse proxy and static web server
- `filebrowser`: browser-based file manager
- `medical-manager-backend`: backend built from
  `https://github.com/nordine-abde/medical-manager.git#main:backend`
- `medical-manager-postgres`: Postgres database for Medical Manager

Caddy also builds and serves the Medical Manager frontend from
`https://github.com/nordine-abde/medical-manager.git#main:frontend`.

The main site is served at `${REDIRECT_SCHEME}://${DOMAIN}` and redirects:

- `/filebrowser` to `filebrowser.${DOMAIN}`
- `/medical-manager` to `medical-manager.${DOMAIN}`

## Fresh Machine Setup

Run the full host setup only on the intended Ubuntu server:

```bash
bash full_setup.sh
```

The script asks for confirmation before making changes. To skip its confirmation
prompt and the prompts in the destructive sub-steps:

```bash
bash full_setup.sh --force
```

`full_setup.sh` runs these scripts in order:

1. `install_docker.sh`
2. `make_docker_rootless.sh`
3. `allow_privileged_ports_to_rootless_docker.sh`
4. `resize_main_disk.sh`
5. `configure_firewall.sh`

After it completes, create `.env`, validate Compose, and start the stack.

## Setup Scripts

### `install_docker.sh`

Adds Docker's official Ubuntu APT repository and installs:

- `docker-ce`
- `docker-ce-cli`
- `containerd.io`
- `docker-buildx-plugin`
- `docker-compose-plugin`

It uses `sudo`, updates APT package indexes, writes
`/etc/apt/sources.list.d/docker.sources`, and stores Docker's signing key in
`/etc/apt/keyrings/docker.asc`.

### `make_docker_rootless.sh`

Installs `uidmap`, runs Docker's rootless setup tool, and disables the system
Docker service and socket:

```bash
dockerd-rootless-setuptool.sh install
sudo systemctl disable --now docker.service docker.socket docker
```

After this step, Docker is expected to run as the current user through the
rootless Docker user service.

### `allow_privileged_ports_to_rootless_docker.sh`

Allows rootless Docker to bind low ports such as `80` and `443` by granting
`cap_net_bind_service` to the `rootlesskit` binary found in the current user's
`PATH`.

It then restarts the rootless Docker user service:

```bash
systemctl --user restart docker
```

### `resize_main_disk.sh`

Extends the logical volume at:

```text
/dev/mapper/ubuntu--vg-ubuntu--lv
```

Then it resizes the filesystem with `resize2fs`.

This assumes the server uses the default Ubuntu LVM path above and that the
volume group has free space available. Run it only after checking the target
host's disk layout.

### `configure_firewall.sh`

Rebuilds the IPv4 and IPv6 filter firewall rules from scratch.

It flushes existing filter rules, deletes custom chains, sets default policies,
and then allows only:

- established and related connections
- loopback traffic
- ICMP / IPv6 ICMP
- TCP port `22`
- TCP port `80`
- TCP port `443`

It installs `iptables-persistent` when missing, saves rules to
`/etc/iptables/rules.v4` and `/etc/iptables/rules.v6`, then enables and restarts
`netfilter-persistent` when `systemctl` is available.

## Utility Scripts

### `utils/generate_ed25519_ssh_key.sh`

Accepts an email address argument and is intended to help generate an SSH key:

```bash
bash utils/generate_ed25519_ssh_key.sh you@example.com
```

At the moment, this script validates that an email argument was passed but does
not actually call `ssh-keygen`.

## Environment

Create a local `.env` from the example file:

```bash
cp .env-example .env
```

Then edit `.env` for the target host.

Important values:

- `DOMAIN`: base domain used by Caddy, for example `home.local`
- `REDIRECT_SCHEME`: `http` or `https`
- `CADDY_DATA_FOLDER`: persistent Caddy data directory
- `CADDY_CONFIG_FOLDER`: persistent Caddy config directory
- `FILE_BROWSER_SRV_FOLDER`: files exposed through File Browser
- `FILE_BROWSER_DATABASE_FOLDER`: File Browser database directory
- `FILE_BROWSER_CONFIG_FOLDER`: File Browser config directory
- `MEDICAL_MANAGER_BETTER_AUTH_URL`: public Medical Manager auth URL
- `MEDICAL_MANAGER_BETTER_AUTH_SECRET`: long random secret
- `MEDICAL_MANAGER_POSTGRES_PASSWORD`: Postgres password
- `MEDICAL_MANAGER_POSTGRES_DATA_FOLDER`: Postgres data directory
- `MEDICAL_MANAGER_DOCUMENTS_FOLDER`: uploaded documents directory
- `MEDICAL_MANAGER_TELEGRAM_BOT_TOKEN`: optional Telegram bot token
- `LOG_LEVEL`: service log level

Compose will fail fast if required Medical Manager secrets are missing.

## Run Services

Validate the Compose file and resolved environment:

```bash
docker compose config
```

Start the services:

```bash
docker compose up -d
```

Check running containers:

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

## Manual Validation

After changing shell scripts:

```bash
bash -n full_setup.sh
bash -n resize_main_disk.sh
bash -n configure_firewall.sh
bash -n utils/generate_ed25519_ssh_key.sh
```

After changing Compose or Caddy configuration:

```bash
docker compose config
```

