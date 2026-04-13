# syntax=docker/dockerfile:1.7

FROM oven/bun:1-alpine AS medical-manager-frontend

WORKDIR /app

COPY --from=medical-manager-frontend-source . .
RUN bun install --frozen-lockfile
RUN bun run build

FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY index.html /srv/index.html
COPY --from=medical-manager-frontend /app/dist /srv/medical-manager

EXPOSE 80 443
