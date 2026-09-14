#!/bin/sh

# Entrypoint: validates secrets, installs/configures WordPress via wp-cli on
# first run, then execs the CMD. Idempotent — safe on every start.

log()
{
	printf "\x1b[33m[ENTRY-SCRIPT]\x1b[0m $*\n"
}

validate_secret()
{
	if [ ! -s "$1" ]; then
		log "\x1b[31merror: secret '$1' is empty\x1b[0m"
		exit 1
	fi
}

set -eu

log "Starting WordPress entry script"

log "Validating secrets are not empty"
validate_secret "$MARIADB_USER_PASSWORD_FILE"
validate_secret "$WORDPRESS_ADMIN_PASSWORD_FILE"
validate_secret "$WORDPRESS_USER_PASSWORD_FILE"
log "  -> success!"

log "Extracting secrets into environment variables"
DATABASE_PASSWORD=$(cat "$MARIADB_USER_PASSWORD_FILE")
WORDPRESS_ADMIN_PASSWORD=$(cat "$WORDPRESS_ADMIN_PASSWORD_FILE")
WORDPRESS_USER_PASSWORD=$(cat "$WORDPRESS_USER_PASSWORD_FILE")
log "  -> success!"

# 42 subject requirement: admin username must not contain "admin"
log "Checking if admin username contains 'admin'"
normalized_admin_name=$(echo "$WORDPRESS_ADMIN_NAME" | tr '[:upper:]' '[:lower:]')
case "$normalized_admin_name" in
	*admin*)
		log "  -> fail: admin username contains 'admin', aborting"
		exit 1
		;;
esac
log "  -> ok"

log "Checking if WordPress core files are present"
if ! wp core version >/dev/null 2>&1; then
	log "  -> missing, downloading WordPress core($WORDPRESS_VERSION)"
	wp core download --version="$WORDPRESS_VERSION"
	log "  -> download complete"
else
	log "  -> present"
fi

log "Checking if wp-config.php exists"
if ! wp config path >/dev/null 2>&1; then
    log "  -> missing, generating wp-config.php"
    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$DATABASE_PASSWORD" \
        --dbhost=mariadb:${MARIADB_PORT} \
        --dbprefix="$WORDPRESS_DB_TABLE_PREFIX" \
        --dbcharset="$DB_CHARSET" \
        --dbcollate="$DB_COLLATE"
	log "  -> wp-config.php created"
else
	log "  -> present"
	log "Checking if correct db host is being used"
	if [ "$(wp config get DB_HOST)" != "mariadb:${MARIADB_PORT}" ]; then
		log "  -> differentiates, updating"
		wp config set DB_HOST "mariadb:${MARIADB_PORT}"
		log "  -> updated"
	else
		log "  -> up to date"
	fi
fi

# append port to site url only for non-standard https ports
site_url="https://$WORDPRESS_DOMAIN"
if [ "$NGINX_PORT" != "443" ]; then
	site_url="$site_url:$NGINX_PORT"
fi

log "Checking if WordPress is installed in the database"
if ! wp core is-installed >/dev/null 2>&1; then
	log "  -> not installed, running wp core install"
	wp core install \
		--url="$site_url" \
		--title="$WORDPRESS_TITLE" \
		--admin_user="$WORDPRESS_ADMIN_NAME" \
		--admin_password="$WORDPRESS_ADMIN_PASSWORD" \
		--admin_email="$WORDPRESS_ADMIN_EMAIL" \
		--skip-email
	log "  -> installation complete"
else
	log "  -> installed"
	log "Checking if correct URL is being used as the site-url"
	if [ "$(wp option get siteurl)" != "$site_url" ]; then
		log "  -> differentiates, updating"
		wp option update siteurl "$site_url"
		log "  -> updated"
	else
		log "  -> up to date"
	fi
	log "Checking if correct URL is being used as the home-url"
	if [ "$(wp option get home)" != "$site_url" ]; then
		log "  -> differentiates, updating"
		wp option update home "$site_url"
		log "  -> updated"
	else
		log "  -> up to date"
	fi
fi

log "Checking if non-admin user exists"
if ! wp user get "$WORDPRESS_USER_NAME" >/dev/null 2>&1; then
	log "  -> not found, creating user '$WORDPRESS_USER_NAME'"
	wp user create \
		"$WORDPRESS_USER_NAME" \
		"$WORDPRESS_USER_EMAIL" \
		--role=author \
		--user_pass="$WORDPRESS_USER_PASSWORD"
	log "  -> user created"
else
	log "  -> exists"
fi

log "script end"

exec "$@"
