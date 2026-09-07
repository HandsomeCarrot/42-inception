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
# healthcheck is defined in docker-compose.yml
ENTRYPOINT ["entry"]
CMD ["mariadbd"]

# exposed to the compose network
EXPOSE 3306
