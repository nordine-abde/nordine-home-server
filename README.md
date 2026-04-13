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

Then update the copied file with the correct paths and `DOMAIN` for your machine.

Set `REDIRECT_SCHEME` in `.env` to control whether `/filebrowser` redirects to `http://` or `https://`.

Set the `MEDICAL_MANAGER_*` values in `.env` before starting the stack. The backend image is built from the public GitHub repository at `https://github.com/nordine-abde/medical-manager.git#main:backend`, runs migrations on startup, stores uploaded documents under `MEDICAL_MANAGER_DOCUMENTS_FOLDER`, and uses the bundled Postgres service as `medical-manager-postgres`. The backend Dockerfile must be pushed to `main` before this remote build context can use it. The Caddy image builds the frontend from `https://github.com/nordine-abde/medical-manager.git#main:frontend`, serves it at `medical-manager.${DOMAIN}`, and forwards `/api/*` to the backend.

## Run
Validate the configuration:

```bash
docker compose config
```

Start the stack:

```bash
docker compose up -d
```
