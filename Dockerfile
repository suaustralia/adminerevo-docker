FROM php:7.4-apache


RUN	echo "upload_max_filesize = 128M" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
&&	echo "post_max_size = 128M" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
&&	echo "memory_limit = 1G" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
&&	echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
&&	echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini

STOPSIGNAL SIGINT

RUN	addgroup --system adminer \
&&	adduser --system --ingroup adminer adminer \
&&	mkdir -p /var/www/html \
&&	mkdir /var/www/html/plugins-enabled \
&&	chown -R adminer:adminer /var/www/html

WORKDIR /var/www/html

# Here you would want to enable all the DB types you need
RUN apt-get update \
    && apt-get install -y \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN	docker-php-ext-install mysqli

COPY	*.php /var/www/html/

ENV	ADMINER_VERSION 4.8.3
ENV	ADMINER_DOWNLOAD_SHA256 d430831b88dc767922a66ff663c1450fb61b6763d60adb26822d481c54a2a186
ENV	ADMINER_COMMIT ae0d5ebf1739d17460d2ee5457d6e33e4bf847b9

RUN	set -x \
&&	curl -fsSL "https://github.com/adminerevo/adminerevo/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php" -o adminer.php \
&&	echo "$ADMINER_DOWNLOAD_SHA256  adminer.php" |sha256sum -c - \
&&	git clone --recurse-submodules=designs --depth 1 --shallow-submodules --branch "v$ADMINER_VERSION" https://github.com/adminerevo/adminerevo.git /tmp/adminer \
&&	commit="$(git -C /tmp/adminer/ rev-parse HEAD)" \
&&	[ "$commit" = "$ADMINER_COMMIT" ] \
&&	cp -r /tmp/adminer/designs/ /tmp/adminer/plugins/ . \
&&	rm -rf /tmp/adminer/

COPY	entrypoint.sh /usr/local/bin/
ENTRYPOINT	[ "entrypoint.sh", "docker-php-entrypoint" ]

USER	adminer

CMD ["apache2-foreground"]

EXPOSE 80