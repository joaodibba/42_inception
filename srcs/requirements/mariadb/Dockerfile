FROM alpine:3.18

RUN apk add --no-cache mariadb mariadb-client mariadb-server-utils && rm -f /var/cache/apk/*

ADD conf/entrypoint.sh /scripts/entrypoint.sh

RUN mkdir /scripts/docker-entrypoint-initdb.d && mkdir /scripts/pre-exec.d && mkdir /scripts/pre-init.d && chmod -R 755 /scripts

COPY ./conf/docker-entrypoint-initdb.d /scripts/docker-entrypoint-initdb.d

COPY ./conf/pre-exec.d /scripts/pre-exec.d

COPY ./conf/pre-init.d /scripts/pre-init.d

EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/scripts/entrypoint.sh"]