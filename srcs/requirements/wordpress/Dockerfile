FROM alpine:3.23

# install wp-cli with GPG signature verification; .build deps removed in same layer
RUN	set -eux; \
	apk --cache=no add \
		curl \
	; \
	apk --cache=no add --virtual .build \
		gpg \
		gpg-agent \
	; \
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.asc; \
	curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/wp-cli.pgp | gpg --import; \
	gpg --verify wp-cli.phar.asc wp-cli.phar; \
	chmod +x wp-cli.phar; \
	mv wp-cli.phar /bin/wp; \
	rm wp-cli.phar.asc; \
	apk del .build;

# php-fpm runtime + extensions required by wordpress
RUN	set -eux; \
	apk --cache=no add \
		fcgi \
		php85 \
		php85-fpm \
		php85-phar \
		php85-mysqli \
		php85-mbstring \
		php85-xml \
		php85-dom \
		php85-curl \
		php85-exif \
		php85-fileinfo \
		php85-intl \
		php85-zip \
		php85-sodium \
		php85-iconv \
	;

# versioned binaries -> unversioned names; unprivileged user for php-fpm
RUN	set -eux; \
	ln -s /usr/bin/php85 /usr/bin/php; \
	ln -s /usr/sbin/php-fpm85 /usr/sbin/php-fpm; \
	adduser -u 1000 -D -S wordpress;

COPY ./config/wp-cli.yml ./wp-cli.yml
COPY --chmod=+x ./config/entry.sh /usr/bin/entry
COPY ./config/php.ini /etc/php85/conf.d/99_inception.ini
COPY ./config/php-fpm.conf /etc/php85/php-fpm.d/www.conf

ENTRYPOINT ["entry"]
CMD ["php-fpm", "-F"]
