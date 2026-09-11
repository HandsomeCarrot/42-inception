FROM alpine:3.23

RUN --mount=type=bind,source=config/nginx_expected_key.txt,target=/tmp/nginx_expected_key.txt \
	set -eux; \
	\
	apk add --no-cache \
		openssl \
		ca-certificates \
		curl \
		gettext-envsubst \
	; \
	curl -fsS -o /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub; \
	\
	openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout > /tmp/nginx_deciphered_key.txt; \
	diff /tmp/nginx_expected_key.txt /tmp/nginx_deciphered_key.txt; \
	\
	rm -f /tmp/nginx_deciphered_key.txt; \
	mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
	\
	echo "@nginx https://nginx.org/packages/alpine/v3.23/main" >> /etc/apk/repositories; \
	apk add --no-cache nginx@nginx; \
	mkdir -p /etc/nginx/ssl/; \
	touch /etc/nginx/ssl/inception.key;

COPY config/nginx.conf /etc/nginx/raw_nginx.conf
COPY config/nginx_security_headers.conf /etc/nginx/security_headers.conf
COPY --chmod=+x config/entry.sh /usr/bin/entry

ENTRYPOINT [ "entry" ]
CMD [ "nginx", "-g", "daemon off;" ]
