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

Then update the copied file with the correct paths, IDs, server `IP`, and `DOMAIN` for your machine.

The DNS container renders its `dnsmasq` config automatically from `IP` and `DOMAIN` in the root `.env`.
Set `REDIRECT_SCHEME` in `.env` to control whether `/filebrowser` redirects to `http://` or `https://`.

## Run
Validate the configuration:

```bash
docker compose config
```

Start the stack:

```bash
docker compose up -d
```
