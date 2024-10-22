FROM debian:11-slim

ENV NGINX_VERSION=1.27.1

# Install dependencies
RUN apt-get update && \
    build_pkgs="build-essential libssl-dev libpcre3-dev zlib1g-dev wget" && \
    runtime_pkgs="ca-certificates openssl libpcre3 zlib1g tzdata git" && \
    apt-get install -y --no-install-recommends $build_pkgs $runtime_pkgs && \
    cd /tmp && \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz && \
    cd /tmp/nginx-${NGINX_VERSION} && \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_realip_module \
        --with-http_slice_module \
        --with-http_v2_module && \
    make && \
    make install && \
    sed -i -e 's/#access_log  logs\/access.log  main;/access_log \/dev\/stdout;/' \
           -e 's/#error_log  logs\/error.log  notice;/error_log stderr notice;/' /etc/nginx/nginx.conf && \
    groupadd -r nginx && \
    useradd -r -d /var/cache/nginx -s /sbin/nologin -g nginx nginx && \
    rm -rf /tmp/* && \
    apt-get purge -y --auto-remove $build_pkgs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create SSL certificate and private key
RUN mkdir -p /etc/nginx/ssl && \
    openssl req \
        -newkey rsa:2048 -nodes -keyout /etc/nginx/ssl/jalves.42.fr.key \
        -x509 -days 365 -out /etc/nginx/ssl/jalves.42.fr.crt \
        -subj "/C=PT/ST=Lisbon/L=Lisbon/O=42Lisbon/OU=42Lisbon/CN=jalves-c.42.fr"

# Set permissions for the SSL certificate and key
RUN chmod 600 /etc/nginx/ssl/jalves.42.fr.key /etc/nginx/ssl/jalves.42.fr.crt

# Copy custom files
COPY conf/index.html /var/www/html/
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Create necessary directories and expose ports
VOLUME ["/var/cache/nginx"]

EXPOSE 80

# Command to start nginx
CMD ["nginx"]
