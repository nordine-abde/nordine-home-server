#!/usr/bin/env bash

set -eu

: "${IP:?IP must be set}"
: "${DOMAIN:?DOMAIN must be set}"

envsubst '${IP} ${DOMAIN}' < /tmp/dnsmasq.conf.template > /etc/dnsmasq.conf

exec dnsmasq --keep-in-foreground --conf-file=/etc/dnsmasq.conf
