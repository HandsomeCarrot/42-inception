FROM alpine:3.23

# busybox-extras provides the httpd applet (not in the base busybox).
# httpd starts as root to bind the port, then drops to the unprivileged user via -u.
RUN set -eux; \
	apk add --no-cache busybox-extras; \
	adduser -u 1001 -D -S static; \
	mkdir -p /home/static;

COPY website/* /home/static/
RUN chown -R static /home/static

HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=3 \
	CMD wget -q -O /dev/null "http://127.0.0.1:$STATIC_PORT/" || exit 1

# -f foreground, -v verbose, -u unprivileged user, -h document root
CMD [ "sh", "-c", "exec httpd -f -v -u static -p \"$STATIC_PORT\" -h /home/static" ]
