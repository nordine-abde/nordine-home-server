FROM caddy:2-alpine

RUN apk add --no-cache gettext

COPY Caddyfile.template /etc/caddy/Caddyfile.template
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY index.html /srv/index.html

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
