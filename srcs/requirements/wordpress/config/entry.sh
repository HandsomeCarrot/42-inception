#!/bin/sh

log()
{
	printf "\x1b[33m[ENTRY-SCRIPT]\x1b[0m %s\n" "$*"
}

set -eu

log "Starting WordPress entry script"

log "Extracting secrets into environment variables"
DATABASE_PASSWORD=$(cat "$MARIADB_USER_PASSWORD_FILE")
WORDPRESS_ADMIN_PASSWORD=$(cat "$WORDPRESS_ADMIN_PASSWORD_FILE")
WORDPRESS_USER_PASSWORD=$(cat "$WORDPRESS_USER_PASSWORD_FILE")

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
	log "  -> missing, downloading WordPress core"
	wp core download --version=6.9
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
        --dbhost=mariadb \
        --dbprefix="$WORDPRESS_DB_TABLE_PREFIX" \
        --dbcharset="$DB_CHARSET" \
        --dbcollate="$DB_COLLATE"
	log "  -> wp-config.php created"
else
	log "  -> present"
fi

log "Checking if WordPress is installed in the database"
if ! wp core is-installed >/dev/null 2>&1; then
	log "  -> not installed, running wp core install"
	wp core install \
		--url="$WORDPRESS_DOMAIN" \
		--title="$WORDPRESS_TITLE" \
		--admin_user="$WORDPRESS_ADMIN_NAME" \
		--admin_password="$WORDPRESS_ADMIN_PASSWORD" \
		--admin_email="$WORDPRESS_ADMIN_EMAIL" \
		--skip-email
	log "  -> installation complete"
else
	log "  -> installed"
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

log "Checking ownership of /home/data"
if [ "$(stat -c '%U:%G' /home/data)" != "wordpress-data:wordpress-data" ]; then
	log "  -> wrong ownership, fixing"
	chown -R wordpress-data:wordpress-data /home/data
	log "  -> ownership corrected"
else
	log "  -> correct"
fi

log "Done"

exec "$@"
