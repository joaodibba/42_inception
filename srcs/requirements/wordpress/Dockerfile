FROM alpine:3.18

RUN apt update && apt install -y wget php7

WORKDIR /var/www/html

RUN wget https://wordpress.org/latest.tar.gz

RUN tar -xzvf latest.tar.gz && rm -rf latest.tar.gz &&

COPY ./conf/wp-config.php /var/www/html/wordpress/wp-config.php

EXPOSE 80

CMD ["php", "-S