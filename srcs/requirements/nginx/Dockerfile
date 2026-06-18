FROM alpine:3.23

# Download, verify the nginx signing key, and install nginx from the
# official repo — all in a single layer so build-only tools don't
# persist in the final image.
#
# The expected key file is injected via a bind mount so it
# never lands in an image layer.
RUN --mount=type=bind,source=config/nginx_expected_key.txt,target=/tmp/nginx_expected_key.txt \
	set -eux; \
	\
	# Install build dependencies as a virtual package so they can
	# be removed cleanly after the key verification step.
	apk add --no-cache --virtual .build-deps openssl curl ca-certificates; \
	\
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
	# Remove build-only tools — they are no longer needed.
	apk del --no-network .build-deps; \
	\
	# Register the nginx stable repository and install nginx.
	echo "@nginx https://nginx.org/packages/alpine/v3.23/main" >> /etc/apk/repositories; \
	apk add --no-cache nginx@nginx

# copy over the nginx config file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# TODO: delete
# echo 127.0.0.1	vpoka.42.fr www.vpoka.42.fr >> /etc/hosts
# RUN	apk update \
# 	&& apk add curl

# TODO: change to 443
EXPOSE 80

CMD [ "nginx", "-g", "daemon off;" ]
