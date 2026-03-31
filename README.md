My home server setup

**Work in progress**

## Warning
Some scripts in this repository make system-level changes and may have destructive side effects, including replacing configuration, changing firewall rules, or reconfiguring host services.
They are intended to be reviewed first and run on a fresh machine you are preparing for this setup, not on an already-configured server you are trying to preserve.
These scripts have already caused enough errors during development that the machine had to be fully reset multiple times. Assume destructive behavior is possible and plan accordingly.

# Nordine Home Server

Home server setup based on Docker Compose, Caddy, and utility shell scripts.

## Setup
Copy the example env file, rename it to `.env`, and edit the values before starting services.

```bash
cp .env-example .env
```

Then update the copied file with the correct paths for your machine.

The stack is served over plain HTTP and is reachable directly by server IP, for example `http://192.168.1.10/` and `http://192.168.1.10/filebrowser/`.

## Run
Validate the configuration:

```bash
docker compose config
```

Start the stack:

```bash
docker compose up -d
```
