#!/bin/sh

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
		-addext "subjectAltName=DNS:$WORDPRESS_DOMAIN,DNS:www.$WORDPRESS_DOMAIN" \
	> /dev/null 2>&1
	log "  -> certificate created successfully"
else
	log "  -> present"
fi

log "Checking if NGINX configuration file needs environment variable substitution"
if [ -f /etc/nginx/raw_nginx.conf ]; then
	log "  -> replacing environment variables"
	envsubst '$WORDPRESS_DOMAIN $NGINX_PORT $WORDPRESS_FPM_PORT' < /etc/nginx/raw_nginx.conf > /etc/nginx/nginx.conf
	log "  -> deleting unsubstituted file"
	rm /etc/nginx/raw_nginx.conf
	log "  -> done!"
else
	log "  -> already substituted"
fi

log "Ended NGINX entry script"

exec "$@"
