FROM alpine:3.19

RUN apk update \
    && apk add redis \
    && rm -rf /var/cache/apk/*

COPY ./tools/redis.sh /tmp/redis.sh

EXPOSE 6379

CMD ["sh", "/tmp/redis.sh"]