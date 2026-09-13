FROM alpine:3.23

# Fetch nginx's official signing key, verify it against the pinned expected key
# (bind-mounted from config/, diff fails the build on mismatch), then trust it
# for apk. Protects against a swapped upstream key.
RUN --mount=type=bind,source=config/nginx_expected_key.txt,target=/tmp/nginx_expected_key.txt \
	set -eux; \
	\
	apk add --no-cache \
		openssl \
		ca-certificates \
		gettext-envsubst \
	; \
	wget -q -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub; \
	\
	openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout > /tmp/nginx_deciphered_key.txt; \
	diff /tmp/nginx_expected_key.txt /tmp/nginx_deciphered_key.txt; \
	\
	rm -f /tmp/nginx_deciphered_key.txt; \
	mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
	\
	# nginx's own apk repo — newer package than alpine's
	echo "@nginx https://nginx.org/packages/alpine/v3.23/main" >> /etc/apk/repositories; \
	apk add --no-cache nginx@nginx; \
	# placeholder key; real cert/key generated at first start by entry.sh
	mkdir -p /etc/nginx/ssl/ /etc/nginx/conf.d/; \
	touch /etc/nginx/ssl/inception.key; \
	mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.template

# wordpress.conf is an envsubst template, rendered to conf.d/wordpress.conf by entry.sh
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/wordpress.conf /home/raw_wordpress.conf
COPY config/nginx_security_headers.conf /etc/nginx/security_headers.conf
COPY --chmod=+x config/entry.sh /usr/bin/entry

ENTRYPOINT [ "entry" ]
CMD [ "nginx", "-g", "daemon off;" ]
