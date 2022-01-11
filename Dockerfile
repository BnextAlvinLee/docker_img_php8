FROM php:8.0.11-fpm-alpine3.14
# PHP extensions

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk update && apk upgrade

RUN set -ex \
    && apk add --no-cache nodejs npm yarn nginx autoconf g++ make libpng-dev curl icu-dev \
    && pecl install redis \
    && docker-php-ext-enable redis
# GD
RUN apk add freetype-dev libjpeg-turbo-dev libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd opcache pdo_mysql sockets fileinfo

RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/php-opocache-cfg.ini

RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer	   


COPY php.ini /usr/local/etc/php/php.ini 
COPY default.conf /etc/nginx/http.d/default.conf
COPY nginx-site.conf /etc/nginx/sites-enabled/default
COPY entrypoint.sh /etc/entrypoint.sh
COPY index.html /var/www/html/public/index.html
COPY info.php /var/www/html/public/info.php
RUN chmod +x /etc/entrypoint.sh


EXPOSE 80 443

ENTRYPOINT ["/etc/entrypoint.sh"]
