# container base system
FROM alpine:3.23

# Install MariaDB server and client.
# - mariadb        : the MariaDB database server
# - mariadb-client : provides CLI tools (mysql, mariadb-install-db, etc.)
# --no-cache       : avoids storing the apk package index, keeping the image smaller
RUN set -ex; \
	apk --no-cache add mariadb=~11.4 mariadb-client=~11.4 gettext-envsubst; \
# creates a directory that is required by mariadb, so it can create a socket?
	mkdir -p /run/mysqld; \
	chown -R mysql:mysql /run/mysqld;

# copy external files to container
COPY config/my.cnf /etc/my.cnf
COPY config/setup.sql /home/config/setup.sql
COPY config/docker-entry.sh /home/config/docker-entry.sh

# give execution permission for entry script
RUN set -ex; \
    chmod +x /home/config/docker-entry.sh

# inform that port 3306 of this container, should be exposed/usable
EXPOSE 3306

HEALTHCHECK --start-period=30s --interval=10s --timeout=5s --retries=3 \
	CMD mariadb -h 127.0.0.1 -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" "$DB_NAME" >/dev/null 2>&1

ENTRYPOINT ["/home/config/docker-entry.sh"]
CMD ["mariadbd"]
