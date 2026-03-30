My home server setup

**Work in progress**

# Nordine Home Server

Home server setup based on Docker Compose, Caddy, and utility shell scripts.

## Setup
Copy the example env file, rename it to `.env`, and edit the values before starting services.

```bash
cp .env-example .env
```

Then update the copied file with the correct paths, IDs, server `IP`, and `DOMAIN` for your machine.

The DNS container renders its `dnsmasq` config automatically from `IP` and `DOMAIN` in the root `.env`.

## Run
Validate the configuration:

```bash
docker compose config
```

Start the stack:

```bash
docker compose up -d
```
