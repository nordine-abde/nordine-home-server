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
- FTP drop box for printer scans
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
- `ftp-scans`: FTP endpoint for printer scan uploads into File Browser
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
- `ROUTER_CONFIG` and `PRINTER_CONFIG` populate landing-page links
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
`cap_net_bind_service` to `rootlesskit` so rootless Docker can bind privileged
ports such as `21`, `80`, and `443`.

`resize_main_disk.sh` extends `/dev/mapper/ubuntu--vg-ubuntu--lv` to use all
free space in the volume group, then resizes the filesystem. This is specific to
the current Ubuntu LVM layout and should be reviewed before reuse.

`configure_firewall.sh` rebuilds IPv4 and IPv6 filter rules from scratch. It
keeps inbound access limited to established connections, loopback, ICMP, SSH,
FTP, HTTP, HTTPS, and the configured FTP passive data ports, then persists the
rules with `iptables-persistent`.

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
- `ROUTER_CONFIG`: router admin URL shown on the landing page
- `PRINTER_CONFIG`: printer admin URL shown on the landing page
- `CADDY_DATA_FOLDER`: persistent Caddy data directory
- `CADDY_CONFIG_FOLDER`: persistent Caddy config directory
- `FILE_BROWSER_SRV_FOLDER`: files exposed through File Browser
- `FILE_BROWSER_DATABASE_FOLDER`: File Browser database directory
- `FILE_BROWSER_CONFIG_FOLDER`: File Browser config directory
- `FILE_BROWSER_ADMIN_PASSWORD`: optional admin password applied to the File
  Browser `admin` user on bootstrap
- `FILE_BROWSER_BOOTSTRAP_USERS`: comma-separated File Browser users to create,
  using `username:password` entries
- `FILE_BROWSER_BOOTSTRAP_SHARED_FOLDERS`: comma-separated shared folders to
  create and link into each bootstrapped user home, using `/path:Alias` entries
- `FILE_BROWSER_MINIMUM_PASSWORD_LENGTH`: minimum password length enforced by
  File Browser for new users
- `FTP_PUBLIC_HOST`: hostname or LAN IP address printers use for FTP passive mode
- `FTP_SCANS_USER`: FTP username for printer uploads
- `FTP_SCANS_PASSWORD`: FTP password for printer uploads
- `FTP_PASSWD_FOLDER`: persistent FTP virtual-user database directory
- `MEDICAL_MANAGER_BETTER_AUTH_URL`: Medical Manager auth URL
- `MEDICAL_MANAGER_BETTER_AUTH_SECRET`: application secret
- `MEDICAL_MANAGER_POSTGRES_PASSWORD`: Postgres password
- `MEDICAL_MANAGER_POSTGRES_DATA_FOLDER`: Postgres data directory
- `MEDICAL_MANAGER_DOCUMENTS_FOLDER`: uploaded documents directory
- `MEDICAL_MANAGER_TELEGRAM_BOT_TOKEN`: optional Telegram bot token
- `LOG_LEVEL`: service log level

Compose is configured to fail fast when required Medical Manager secrets are
missing.

## Printer Scan Uploads

`ftp-scans` exposes FTP on port `21` and passive data ports `30000-30009`.
Printer scans are stored in `${FILE_BROWSER_SRV_FOLDER}/scans`, which appears
as `/scans` in File Browser and can be linked into configured user homes.

`filebrowser-bootstrap` creates configured shared folders, enables File
Browser's `createUserDir` setting, creates configured users, scopes them to
`/home/<user>`, and links each shared folder into each bootstrapped user home.

Configure the printer with:

- Host: the server LAN address, or the value of `FTP_PUBLIC_HOST`
- Port: `21`
- Protocol: FTP
- Passive mode: enabled, if the printer offers the option
- Username: `FTP_SCANS_USER`
- Password: `FTP_SCANS_PASSWORD`
- Remote folder: `/`

## File Browser Users

File Browser users are application users stored in
`${FILE_BROWSER_DATABASE_FOLDER}/filebrowser.db`; they are not Linux accounts.
To create users and shared folders automatically when the stack starts, set:

```env
FILE_BROWSER_ADMIN_PASSWORD=replace-with-a-strong-admin-password
FILE_BROWSER_BOOTSTRAP_USERS=user1:replace-with-a-strong-password,user2:replace-with-another-password
FILE_BROWSER_BOOTSTRAP_SHARED_FOLDERS=/scans:Scans,/documents:Documents
FILE_BROWSER_MINIMUM_PASSWORD_LENGTH=12
```

On bootstrap, this creates or updates the File Browser `admin` user when
`FILE_BROWSER_ADMIN_PASSWORD` is set. It also creates
`${FILE_BROWSER_SRV_FOLDER}/home/user1` and
`${FILE_BROWSER_SRV_FOLDER}/home/user2`, scopes the users to `/home/user1` and
`/home/user2`, creates `/scans` and `/documents`, and links both shared folders
into both user homes.

Existing non-admin users keep their current password. If a listed user already
exists, bootstrap only updates that user's scope and shared-folder links. If a
listed user does not exist, the `username:password` entry must include a
password. When both `FILE_BROWSER_ADMIN_PASSWORD` and
`FILE_BROWSER_BOOTSTRAP_USERS` are empty and no File Browser database exists
yet, bootstrap only prepares shared directories and leaves first-run database
setup to File Browser.

`FILE_BROWSER_MINIMUM_PASSWORD_LENGTH` is applied to the File Browser database
on each bootstrap run. It affects new passwords; existing passwords are not
rewritten.

For one-off users or later changes, run:

```bash
./create_filebrowser_user.sh user1 /scans:Scans
```

This creates `${FILE_BROWSER_SRV_FOLDER}/home/user1`, creates or updates the
File Browser user `user1` with scope `/home/user1`, and links `/scans` into the
user home as `Scans`. The script also enables File Browser's `createUserDir`
database setting so future user creation defaults create user directories.

For non-interactive use, provide the new-user password through the environment:

```bash
FILE_BROWSER_NEW_USER_PASSWORD='replace-with-a-strong-password' \
  ./create_filebrowser_user.sh user1 /scans:Scans
```

By default, shared folders are attached with relative symlinks. If File Browser
or a future policy rejects symlinks outside the scoped home, use host bind
mounts instead:

```bash
./create_filebrowser_user.sh --mode bind user1 /scans:Scans
```

Bind mounts may require `sudo` and are not persistent across reboot unless they
are also configured in `/etc/fstab` or a systemd mount unit.

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
