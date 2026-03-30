# Repository Guidelines

## Project Structure & Module Organization
This repository is a small home-server setup built around shell scripts and Docker Compose.

- Root scripts such as `install_docker.sh` and `make_docker_rootless.sh` handle machine setup tasks.
- [`utils/`](/home/abdessamad/apps/nordine-home-server/utils) contains reusable helper scripts, currently `generate_ed25519_ssh_key.sh`.
- [`docker-compose.yaml`](/home/abdessamad/apps/nordine-home-server/docker-compose.yaml) defines long-running services.
- [`config/`](/home/abdessamad/apps/nordine-home-server/config) is reserved for configuration artifacts; keep service-specific files there when possible.

Prefer one script per concern, with descriptive names like `install_<tool>.sh` or `configure_<service>.sh`.

## Build, Test, and Development Commands
- `bash install_docker.sh`: installs Docker Engine and Compose plugin on Ubuntu-based hosts.
- `bash make_docker_rootless.sh`: switches the machine to rootless Docker.
- `bash utils/generate_ed25519_ssh_key.sh you@example.com`: creates an SSH key interactively.
- `docker compose config`: validates `docker-compose.yaml` before committing.
- `docker compose up -d`: starts the defined services in the background.

Run scripts from the repository root so relative paths in Compose and future scripts resolve correctly.

## Coding Style & Naming Conventions
Use Bash for setup scripts unless a stronger reason exists. Follow the current style:

- 2-space indentation in shell and YAML.
- Lowercase, underscore-separated filenames, for example `generate_ed25519_ssh_key.sh`.
- Add `#!/usr/bin/env bash` and `set -e` to executable Bash scripts.
- Keep comments practical and task-oriented; avoid restating obvious commands.

Validate shell scripts with `bash -n <script>` and format YAML consistently.

## Testing Guidelines
There is no automated test suite yet. For now, treat validation as mandatory:

- Run `bash -n` on every modified shell script.
- Run `docker compose config` after editing Compose files.
- In pull requests, note the exact manual checks performed and the target environment, for example `Ubuntu 24.04`.

## Commit & Pull Request Guidelines
Recent history uses short, imperative commit messages such as `removed dnsmasq` and `partial docker compose`. Keep commits focused and use the same pattern, but be slightly more specific when useful.

PRs should include:
- A short summary of the infrastructure change.
- Any required environment variables, paths, or sudo steps.
- Manual verification steps and relevant command output if behavior changed.
