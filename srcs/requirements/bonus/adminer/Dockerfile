FROM alpine:3.23

RUN set -eux; \
	apk --cache=no add \
		php85 \
		php85-mysqli \
		php85-session \
	; \
	mkdir -p /home/adminer; \
	wget -q -O /home/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v6.0.2/adminer-6.0.2.php

HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=3 \
	CMD wget -q -T 4 -O /dev/null "http://127.0.0.1:$ADMINER_PORT/" || exit 1

CMD [ "sh", "-c", "exec php85 -S \"0.0.0.0:$ADMINER_PORT\" /home/adminer/adminer.php" ]
