FROM debian:11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-client \
    mariadb-server \
    gosu \
    util-linux \
    bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d && \
    mkdir -p /scripts/pre-exec.d && \
    mkdir -p /scripts/pre-init.d && \
    chmod -R 755 /scripts

COPY /conf/run.sh /scripts/run.sh
COPY ./tools/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
COPY ./tools/pre-exec.d /scripts/pre-exec.d
COPY ./tools/pre-init.d /scripts/pre-init.d

ENTRYPOINT ["/scripts/run.sh"]