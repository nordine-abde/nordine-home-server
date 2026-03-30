#!/bin/sh

set -eu

: "${DOMAIN:?DOMAIN must be set}"

AUTO_SSL="${AUTO_SSL:-true}"
GLOBAL_OPTIONS=""
REDIRECT_SCHEME="https"

if [ "$AUTO_SSL" = "false" ]; then
  GLOBAL_OPTIONS="$(printf '{\n  auto_https off\n}\n')"
  REDIRECT_SCHEME="http"
fi

export DOMAIN GLOBAL_OPTIONS REDIRECT_SCHEME
envsubst < /etc/caddy/Caddyfile.template > /etc/caddy/Caddyfile

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
