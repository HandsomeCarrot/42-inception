# ALPINE
# container base system
FROM alpine:3.23

# VOLUME ["/var/lib/mysql"]

ENV MARIADB_DATADIR=/var/lib/mysql
ENV MARIADB_CONFIG=/etc/my.cnf
ENV SCRIPT_DIR=/usr/local/bin

# copy external files to container
COPY my.cnf ${MARIADB_CONFIG}
COPY docker-entry.sh ${SCRIPT_DIR}/docker-entry.sh
# COPY healthcheck.sh ${SCRIPT_DIR}/healthcheck.sh

# Install MariaDB server and client.
# - mariadb        : the MariaDB database server
# - mariadb-client : provides CLI tools (mysql, mariadb-install-db, etc.)
# --no-cache       : avoids storing the apk package index, keeping the image smaller
RUN apk --no-cache add mariadb mariadb-client

# creates a directory that is required by mariadb, so it can create a socket?
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

RUN chmod +x ${SCRIPT_DIR}/docker-entry.sh #${SCRIPT_DIR}/healthcheck.sh

# USER mysql

ENTRYPOINT ["docker-entry.sh"]

# inform that port 3306 of this container, should be exposed/usable
EXPOSE 3306

CMD ["mariadbd", "--user=mysql"]

# HEALTHCHECK --interval=10s --timeout=5s --retries=5 CMD ["/usr/local/bin/healthcheck.sh"]