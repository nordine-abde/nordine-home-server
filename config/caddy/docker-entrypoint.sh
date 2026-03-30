#!/bin/sh

set -eu

: "${DOMAIN:?DOMAIN must be set}"

AUTO_SSL="${AUTO_SSL:-true}"
REDIRECT_SCHEME="https"

if [ "$AUTO_SSL" = "false" ]; then
  REDIRECT_SCHEME="http"
fi

export DOMAIN REDIRECT_SCHEME
envsubst < /etc/caddy/Caddyfile.template > /etc/caddy/Caddyfile

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
