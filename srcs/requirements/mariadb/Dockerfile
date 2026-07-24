# container base system
FROM alpine:3.23

# Install MariaDB server and client.
RUN set -eux; \
	apk --no-cache add mariadb=~11.4 mariadb-client=~11.4 gettext-envsubst; \
# creates a directory that is required by mariadb, so it can create a socket?
	mkdir -p /run/mysqld; \
	chown -R mysql:mysql /run/mysqld;

# copy external files to container
COPY --chmod=+x ./config/entry.sh /home/config/
COPY ./config/my.cnf /home/config/
COPY ./config/setup.sql /home/config/

# inform that port 3306 of this container, should be exposed to the compose network
EXPOSE 3306

HEALTHCHECK --start-period=30s --interval=10s --timeout=5s --retries=3 \
	CMD mariadb -h 127.0.0.1 -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" "$DB_NAME" >/dev/null 2>&1

ENTRYPOINT ["/home/config/entry.sh"]
CMD ["mariadbd"]
