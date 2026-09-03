FROM alpine:3.23

# Download, verify the nginx signing key, and install nginx from the
# official repo.
#
# The expected key file is injected via a bind mount so it
# never lands in an image layer.
RUN --mount=type=bind,source=config/nginx_expected_key.txt,target=/tmp/nginx_expected_key.txt \
	set -eux; \
	\
	# TODO: docs
	apk add --no-cache \
		openssl \
		ca-certificates \
		curl \
		gettext-envsubst \
	; \
	# Download the official nginx signing key from nginx.org.
	curl -fsS -o /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub; \
	\
	# Decode the downloaded public key and diff it against the
	# expected fingerprint to detect tampering.
	openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout > /tmp/nginx_deciphered_key.txt; \
	diff /tmp/nginx_expected_key.txt /tmp/nginx_deciphered_key.txt; \
	\
	# Clean up the temporary decoded key and install the verified
	# key into apk's trust store.
	rm -f /tmp/nginx_deciphered_key.txt; \
	mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
	\
	# Register the nginx stable repository and install nginx.
	echo "@nginx https://nginx.org/packages/alpine/v3.23/main" >> /etc/apk/repositories; \
	apk add --no-cache nginx@nginx; \
	mkdir -p /etc/nginx/ssl/; \
	touch /etc/nginx/ssl/inception.key;

# copy over the config files
COPY config/nginx.conf /etc/nginx/raw_nginx.conf
COPY --chmod=+x config/entry.sh /usr/bin/entry

ENTRYPOINT [ "entry" ]
CMD [ "nginx", "-g", "daemon off;" ]

EXPOSE 443
