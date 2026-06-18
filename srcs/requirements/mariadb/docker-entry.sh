#!/bin/sh

# changes behaviour of shell failures
# -e
#   shell exits if any command fails (does not change the pipe behaviour, where only the last command determines the outcome)
# -u:
#   expansions fail with consequences (also prints error message)
#
# In combination they make the script exit/stop if any error happens along the way.
# - command failure
# - variable expansion
set -eu

echo "[ENTRY SCRIPT] executing..."

if [ ! -d "${MARIADB_DATADIR}/mysql" ]; then
	echo "[ENTRY SCRIPT] no database found, creating ..."
	mariadb-install-db \
		--defaults-file="${MARIADB_CONFIG}" \
		--datadir="${MARIADB_DATADIR}" \
		--user=mysql \
		--skip-test-db
else
	echo "[ENTRY SCRIPT] found database"
fi

echo "[ENTRY SCRIPT] finished."

exec "$@"