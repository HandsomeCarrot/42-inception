FROM alpine:3.23

RUN set -eux; \
	apk --no-cache add \
		mariadb=~11.4 \
		mariadb-client=~11.4 \
		gettext-envsubst \
	; \
	mkdir -p /run/mysqld; \
	chown -R mysql:mysql /run/mysqld;

COPY --chmod=+x ./config/entry.sh /usr/bin/entry
COPY ./config/setup.sql /home/
COPY ./config/my.cnf /home/

ENTRYPOINT ["entry"]
CMD ["mariadbd"]
