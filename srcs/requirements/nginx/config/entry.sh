#!/bin/sh

# Entrypoint: generates a self-signed TLS certificate on first start,
# renders the nginx config template, then execs the CMD.

log()
{
	printf "\x1b[33m[ENTRY-SCRIPT]\x1b[0m %s\n" "$*"
}

set -eu

log "Starting NGINX entry script"

log "Checking if a site certificate exists"
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
	log "  -> missing, creating a new self-signed certificate"
	openssl req \
		-x509 \
		-nodes \
		-days 365 \
		-newkey rsa:3072 \
		-keyout /etc/nginx/ssl/inception.key \
		-out /etc/nginx/ssl/inception.crt \
		-subj "/CN=$WORDPRESS_DOMAIN" \
		-addext "subjectAltName=DNS:$WORDPRESS_DOMAIN,DNS:*.$WORDPRESS_DOMAIN" \
	> /dev/null 2>&1
	log "  -> certificate created successfully"
else
	log "  -> present"
fi

log "Checking if the site configurations need environment variable substitution"
if [ -f /home/wordpress.conf ]; then
	log "  -> replacing environment variables in wordpress.conf"
	envsubst '$WORDPRESS_DOMAIN $NGINX_PORT $WORDPRESS_FPM_PORT' < /home/wordpress.conf > /etc/nginx/conf.d/wordpress.conf
	rm /home/wordpress.conf
else
	log "  -> wordpress.conf already substituted"
fi
if [ -f /home/adminer.conf ]; then
	log "  -> replacing environment variables in adminer.conf"
	envsubst '$ADMINER_SUBDOMAIN $WORDPRESS_DOMAIN $ADMINER_PORT $NGINX_PORT' < /home/adminer.conf > /etc/nginx/conf.d/adminer.conf
	rm /home/adminer.conf
else
	log "  -> adminer.conf already substituted"
fi
if [ -f /home/static.conf ]; then
	log "  -> replacing environment variables in static.conf"
	envsubst '$STATIC_SUBDOMAIN $WORDPRESS_DOMAIN $STATIC_PORT $NGINX_PORT' < /home/static.conf > /etc/nginx/conf.d/static.conf
	rm /home/static.conf
else
	log "  -> static.conf already substituted"
fi
log "  -> done!"

log "Ended NGINX entry script"

exec "$@"
