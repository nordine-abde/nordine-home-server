FROM alpine:3.22

RUN apk add --no-cache bash dnsmasq gettext

COPY dnsmasq.conf.template /tmp/dnsmasq.conf.template
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
