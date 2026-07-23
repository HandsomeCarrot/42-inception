#!/bin/sh

log()
{
	printf "\x1b[33m[ENTRY-SCRIPT]\x1b[0m %s\n" "$*"
}

set -eux

log "starting script"

if [ ! -d "/home/data/mysql" ]; then
	log "creating system database and tables 'mysql'."
	mariadb-install-db --skip-test-db
else
	log "system database is already set up: skipped step!"
fi

if [ ! -d "/home/data/${DB_NAME}" ]; then
	log "couldn't find database '${DB_NAME}': creating new database."

	log "replacing environment variables in setup.sql."
	envsubst '${DB_ROOT_PASSWORD} ${DB_NAME} ${DB_USER} ${DB_PASSWORD}' < "/home/config/setup.sql" > "/tmp/setup.sql"

	log "bootstrapping mariadb."
	mariadbd --bootstrap < /tmp/setup.sql
	log "bootstrap complete."
else
	log "database '${DB_NAME}' already exists: skipped step!"
fi

if [ -f "/tmp/setup.sql" ]; then
	log "removing substituted 'setup.sql'"
	rm -f /tmp/setup.sql
else
	log "substituted 'setup.sql' already removed: skipped step!"
fi

log "script end"

exec "$@"
