# Nordine Home Server

Home server setup based on Docker Compose, Caddy, and utility shell scripts.

## Setup
Copy the example env files, rename them to `.env`, and edit the values before starting services.

```bash
cp .env-example .env
cp config/caddy/.env-example config/caddy/.env
```

Then update the copied files with the correct paths, IDs, and domain for your machine.

## Run
Validate the configuration:

```bash
docker compose config
```

Start the stack:

```bash
docker compose up -d
```


