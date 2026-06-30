#!/bin/sh

DOMAIN_NAME="${DOMAIN_NAME}"

if [ ! -f /etc/nginx/ssl/site.crt ]; then
# could encrypt with ECDSA, but that is probably overkill for project
	openssl req \
		-x509 \
		-nodes \
		-days 365 \
		-newkey rsa:3072 \
		-keyout /etc/nginx/ssl/inception.key \
		-out /etc/nginx/ssl/inception.crt \
		-subj "/CN=$DOMAIN_NAME" \
		-addext "subjectAltName=DNS:$DOMAIN_NAME,DNS:www.$DOMAIN_NAME"
fi

exec "$@"