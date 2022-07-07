FROM php:8.0-fpm as BUILDER

LABEL \
  maintainer="lightningspirit" \
  vendor="Move Your Digital, Ltd."

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends; \
	rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  apt-get update; \
	apt-get install -y --no-install-recommends \
		libmemcachedutil2 \
		libmemcached-dev \
		libmemcached11 \
  	libzip-dev \
		curl \
  	git \
  ; \
  \
  docker-php-ext-install -j "$(nproc)" \
		zip \
	; \
	\
  pecl install apcu; \
  pecl install memcached;

WORKDIR /usr/src/build
COPY ./composer.json /usr/src/build/composer.json
COPY --from=composer/composer /usr/bin/composer /usr/bin/composer
RUN set -eux; \
  cd /usr/src/build; \
  composer update; \
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
	chmod +x wp-cli.phar;

FROM wordpress:6.0-php8.0-fpm
COPY --from=BUILDER /usr/src/build /usr/src/wordpress
COPY --from=composer/composer /usr/bin/composer /usr/bin/composer
COPY --from=BUILDER /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=moveyourdigital/wait-for-it /wait-for-it.sh /usr/bin/wait-for-it

# set production PHP.ini settings
# see https://secure.php.net/manual/en/apcu.installation.php
# see https://secure.php.net/manual/en/opcache.installation.php
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libmemcachedutil2 \
		libmemcached11 \
		mariadb-client \
		netcat \
		unzip \
		less \
		curl \
		cron \
		htop \
  	git \
		zip \
	; \
	\
  docker-php-ext-enable apcu; \
	docker-php-ext-enable opcache; \
	docker-php-ext-enable memcached; \
	{ \
		echo 'opcache.memory_consumption = 128'; \
		echo 'opcache.interned_strings_buffer = 64'; \
		echo 'opcache.max_accelerated_files = 192480'; \
    echo 'opcache.validate_timestamps = 1'; \
		echo 'opcache.revalidate_freq = 5'; \
		echo 'opcache.max_file_size = 31457280'; \
		echo 'opcache.file_update_protection = 0'; \
		echo 'opcache.file_cache_consistency_checks = 0'; \
    echo 'opcache.fast_shutdown = 1'; \
		echo 'opcache.file_cache = /var/www/opcache_files'; \
    echo 'opcache.enable_cli = 0'; \
		echo 'opcache.enable = 1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
  { \
		echo 'apc.enable_cli = 1'; \
		echo 'apc.enabled = 1'; \
	} > /usr/local/etc/php/conf.d/apcu-recommended.ini; \
	{ \
		echo 'session.save_handler = memcached'; \
		echo 'session.save_path = "memcached:11211"'; \
	} > /usr/local/etc/php/conf.d/session-recommended.ini; \
	\
	{ \
		echo 'post_max_size = 32M'; \
		echo 'upload_max_filesize = 20M'; \
	} > /usr/local/etc/php/conf.d/upload-recommended.ini; \
	\
	{ \
		echo 'max_execution_time = 300'; \
		echo 'memory_limit = 512M'; \
	} > /usr/local/etc/php/conf.d/common-recommended.ini; \
	\
	{ \
		echo 'pm = dynamic'; \
		echo 'pm.max_children = 64'; \
		echo 'pm.start_servers = 16'; \
		echo 'pm.min_spare_servers = 8'; \
		echo 'pm.max_spare_servers = 16'; \
		echo 'pm.max_requests = 256'; \
		echo 'pm.process_idle_timeout = 10s'; \
		echo 'pm.status_path = /status'; \
		echo 'ping.path = /ping'; \
	} >> /usr/local/etc/php-fpm.d/zz-docker.conf; \
	\
	mkdir /var/www/opcache_files; \
	chown www-data:www-data /var/www/opcache_files; \
	\
	{ \
		echo 'PATH="/usr/local/bin:/usr/bin:/bin"'; \
		echo '# Runs WP cron every minute'; \
		echo "* * * * * cd /var/www/html; wp cron event run --due-now > /proc/1/fd/1 2>&1"; \
	} > /etc/cron.d/default; \
	\
	crontab -u www-data /etc/cron.d/default; \
	chmod 0644 /etc/cron.d/default; \
	chmod u+s /usr/sbin/cron; \
	\
	mv /usr/src/wordpress/wp-cli.phar /usr/local/bin/wp;

COPY --chown=www-data:www-data ./autoload.php /usr/src/wordpress/wp-content/mu-plugins/autoload.php
COPY docker-entrypoint.sh /usr/local/bin/

HEALTHCHECK --interval=30s --timeout=3s --start-period=2m --retries=3 CMD ["nc", "-z", "127.0.0.1", "9000"]

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
