# container base system
FROM alpine:3.23

RUN set -eux; \
# Install MariaDB server and client.
	apk --no-cache add \
		mariadb=~11.4 \
		mariadb-client=~11.4 \
		gettext-envsubst \
	; \
	mkdir -p /run/mysqld; \
	chown -R mysql:mysql /run/mysqld;

# copy external files to container
COPY --chmod=+x ./config/entry.sh /usr/bin/entry
COPY ./config/setup.sql /home/
COPY ./config/my.cnf /home/

# password is read from the [client] section of my.cnf (substituted at runtime with the user password secret)
HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=3 \
	CMD mariadb -h 127.0.0.1 -u"$WORDPRESS_DB_USER" -e "SELECT 1" "$WORDPRESS_DB_NAME" >/dev/null 2>&1

ENTRYPOINT ["entry"]
CMD ["mariadbd"]

# exposed to the compose network
EXPOSE 3306
