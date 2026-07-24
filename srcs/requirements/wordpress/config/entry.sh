#!/bin/sh

log()
{
	printf "\x1b[33m[ENTRY-SCRIPT]\x1b[0m %s\n" "$*"
}

set -eu

log "START"

log "checking if wordpress core files are on system"
if ! wp core version >/dev/null 2>&1; then
	log "  -> error: downloading..."
	wp core download --version=6.9
	log "  -> done!"
else
	log "  -> success!"
fi


log "checking if wordpress config file exists"
if ! wp config path >/dev/null 2>&1; then
	log "  -> error: creating..."
	# generate the wordpress config with the wp-cli
	wp config create \
		--dbname=${DB_NAME} \
		--dbuser=${DB_USER} \
		--dbpass=${DB_PASSWORD} \
		--dbhost=mariadb \
		--dbprefix=${DB_TABLE_PREFIX} \
		--dbcharset=${DB_CHARSET} \
		--dbcollate=${DB_COLLATE}
	log "  done!"
else
	log "  -> success!"
fi

log "checking if database is set up for wordpress"
if ! wp core is-installed >/dev/null 2>&1; then
	log "  -> error: setting up..."
	wp core install \
		--url=${DOMAIN} \
		--title=${TITLE} \
		--admin_user=${WORDPRESS_ADMIN} \
		--admin_password=${WORDPRESS_ADMIN_PASSWORD} \
		--admin_email=${WORDPRESS_ADMIN_EMAIL} \
		--skip-email
	log "  -> done!"
else
	log "  -> success!"
fi

log "END"

exec "$@"
