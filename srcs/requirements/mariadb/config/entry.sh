#!/bin/sh

# Entrypoint: validates secrets, renders config templates, initializes the
# database on first run, then execs the CMD. Idempotent — safe on every start.

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
# envsubst is whitelisted — only these vars get substituted
envsubst '$DB_CHARSET $DB_COLLATE $MARIADB_USER_PASSWORD $MARIADB_PORT' < /home/my.cnf > /etc/my.cnf

# first run detection: datadir exists only after mariadb-install-db
log "checking if base databases are created"
if [ ! -d "/home/data-drive/mysql" ]; then
	log "  -> error: creating..."
	mariadb-install-db --skip-test-db
	log "  -> done!"
else
	log "  -> success!"
fi

# db dirs exist only after setup.sql was applied (first run)
log "checking if wordpress database exists"
if [ ! -d "/home/data-drive/${WORDPRESS_DB_NAME}" ]; then
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
