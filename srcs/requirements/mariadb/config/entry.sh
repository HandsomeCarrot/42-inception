#!/bin/sh

log()
{
	printf "\x1b[33m[ENTRY-SCRIPT]\x1b[0m %s\n" "$*"
}

set -eu

log "START"

log "extracting secrets into environment variables"
MARIADB_ROOT_PASSWORD=$(cat "$MARIADB_ROOT_PASSWORD_FILE")
MARIADB_WORDPRESS_USER_PASSWORD=$(cat "$MARIADB_WORDPRESS_USER_PASSWORD_FILE")
export MARIADB_ROOT_PASSWORD MARIADB_WORDPRESS_USER_PASSWORD

log "replacing environment variables in my.cnf"
envsubst '$DATABASE_CHARSET $DATABASE_COLLATE $MARIADB_WORDPRESS_USER_PASSWORD' < /etc/my.cnf > /tmp/my.cnf
cat /tmp/my.cnf > /etc/my.cnf

log "checking if base databases are created"
if [ ! -d "/home/data/mysql" ]; then
	log "  -> error: creating..."
	mariadb-install-db --skip-test-db
	log "  -> done!"
else
	log "  -> success!"
fi

log "checking if wordpress database exists"
if [ ! -d "/home/data/${DB_NAME}" ]; then
	log "  -> error: creating..."

	log "    -> replacing environment variables in setup.sql"
	envsubst '${MARIADB_ROOT_PASSWORD} ${DB_NAME} ${DB_USER} ${MARIADB_WORDPRESS_USER_PASSWORD}' < "/home/setup.sql" > "/tmp/setup.sql"

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
