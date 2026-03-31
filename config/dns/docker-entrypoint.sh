#!/usr/bin/env bash

set -eu

: "${IP:?IP must be set}"
: "${DOMAIN:?DOMAIN must be set}"
: "${UPSTREAM_DNS_1:?UPSTREAM_DNS_1 must be set}"
: "${UPSTREAM_DNS_2:?UPSTREAM_DNS_2 must be set}"

envsubst '${IP} ${DOMAIN} ${UPSTREAM_DNS_1} ${UPSTREAM_DNS_2}' < /tmp/dnsmasq.conf.template > /etc/dnsmasq.conf

exec dnsmasq --keep-in-foreground --conf-file=/etc/dnsmasq.conf
