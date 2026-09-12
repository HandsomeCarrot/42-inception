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

ENTRYPOINT ["entry"]
CMD ["mariadbd"]
