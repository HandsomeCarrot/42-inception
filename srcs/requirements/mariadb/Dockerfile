FROM alpine:3.23

# install mariadb + envsubst (envsubst renders config templates at container start)
RUN set -eux; \
	apk --no-cache add \
		mariadb=~11.4 \
		mariadb-client=~11.4 \
		gettext-envsubst \
	; \
	mkdir -p /run/mysqld; \
	chown -R mysql:mysql /run/mysqld;

# entry script renders these templates into their real locations (envsubst)
COPY --chmod=+x ./config/entry.sh /usr/bin/entry
COPY ./config/setup.sql /home/
COPY ./config/my.cnf /home/

HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=3 \
	CMD mariadb -h 127.0.0.1 -u"$WORDPRESS_DB_USER" -e "SELECT 1" "$WORDPRESS_DB_NAME" >/dev/null 2>&1

ENTRYPOINT ["entry"]
CMD ["mariadbd"]
