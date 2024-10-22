FROM debian:11-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends mariadb-client mariadb-server

RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d && \
    mkdir -p /scripts/pre-exec.d && \
    mkdir -p /scripts/pre-init.d && \
    chmod -R 755 /scripts

COPY /conf/run.sh /scripts/run.sh

EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/scripts/run.sh"]