#!/bin/sh

log()
{
	printf "\x1b[33m[ENTRY-SCRIPT]\x1b[0m %s\n" "$*"
}

validate_secret()
{
	if [ ! -s "$1" ]; then
		log "error: secret '$1' is empty"
		exit 1
	fi
}

set -eu

log "START"

log "Validating secrets are not empty"
validate_secret "$MARIADB_ROOT_PASSWORD_FILE"
validate_secret "$MARIADB_USER_PASSWORD_FILE"
log "  -> success!"

log "Extracting secrets into environment variables"
MARIADB_ROOT_PASSWORD=$(cat "$MARIADB_ROOT_PASSWORD_FILE")
MARIADB_USER_PASSWORD=$(cat "$MARIADB_USER_PASSWORD_FILE")
export MARIADB_ROOT_PASSWORD MARIADB_USER_PASSWORD
log "  -> success!"

log "replacing environment variables in my.cnf"
envsubst '$DB_CHARSET $DB_COLLATE $MARIADB_USER_PASSWORD $MARIADB_PORT' < /home/my.cnf > /etc/my.cnf

log "checking if base databases are created"
if [ ! -d "/home/database/mysql" ]; then
	log "  -> error: creating..."
	mariadb-install-db --skip-test-db
	log "  -> done!"
else
	log "  -> success!"
fi

log "checking if wordpress database exists"
if [ ! -d "/home/database/${WORDPRESS_DB_NAME}" ]; then
	log "  -> error: creating..."

	log "    -> replacing environment variables in setup.sql"
	envsubst '${MARIADB_ROOT_PASSWORD} ${WORDPRESS_DB_NAME} ${WORDPRESS_DB_USER} ${MARIADB_USER_PASSWORD}' < "/home/setup.sql" > "/tmp/setup.sql"

	log "    -> bootstrapping mariadb"
	mariadbd --bootstrap < /tmp/setup.sql
	log "  -> done!"
else
	log "  -> success!"
fi

log "checking if substituted file 'setup.sql' was removed"
if [ -f "/tmp/setup.sql" ]; then
	log "  -> error: removing..."
	rm -f /tmp/setup.sql
	log "  -> done!"
else
	log "  -> success!"
fi

log "END"

exec "$@"
