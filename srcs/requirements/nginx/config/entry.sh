#!/bin/sh

log()
{
	printf "\x1b[33m[ENTRY-SCRIPT]\x1b[0m %s\n" "$*"
}

set -eu

log "Starting NGINX entry script"

# In a environment this should not be self signed.
log "Checking if a site certificate exists"
if [ ! -f /etc/nginx/ssl/site.crt ]; then
	log "  -> missing, creating a new self-signed certificate"
# could encrypt with ECDSA, but that is probably overkill for project
	openssl req \
		-x509 \
		-nodes \
		-days 365 \
		-newkey rsa:3072 \
		-keyout /etc/nginx/ssl/inception.key \
		-out /etc/nginx/ssl/inception.crt \
		-subj "/CN=$WORDPRESS_DOMAIN" \
		-addext "subjectAltName=DNS:$WORDPRESS_DOMAIN,DNS:www.$WORDPRESS_DOMAIN"
	log "  -> certificate created successfully"
else
	log "  -> present"
fi

log "replacing environment variables in nginx.conf"
envsubst '$WORDPRESS_DOMAIN' < /etc/nginx/nginx.conf > /tmp/my.cnf
cat /tmp/my.cnf > /etc/nginx/nginx.conf

exec "$@"
