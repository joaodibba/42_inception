FROM debian:11

RUN apt update && apt install -y \
	nginx \
	openssl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
   -keyout /etc/nginx/ssl/nginx.key \
   -out /etc/nginx/ssl/nginx.crt \
   -subj "/C=PT/ST=Lisbon/L=Lisbon/O=42Lisbon/OU=42Lisbon/CN=jalves-c"

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]