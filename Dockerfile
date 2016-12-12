FROM alpine:3.4
EXPOSE 8080

ENV NGINX_URL="http://nginx.org/download/nginx-1.10.2.tar.gz" \
    build_pkgs="build-base linux-headers openssl-dev pcre-dev zlib-dev wget curl py-pip" \
    runtime_pkgs="ca-certificates openssl pcre zlib dumb-init supervisor fabric" \
    NGINX_OPTS="--user=nginx \
                --group=nginx \
                --with-http_realip_module \
                --with-http_ssl_module \
                --sbin-path=/usr/sbin/ \
                --prefix=/etc/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --http-client-body-temp-path=/var/cache/nginx/client_temp \
                --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
                --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
                --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
                --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
                --http-log-path=/var/log/nginx/access.log \
                --with-http_stub_status_module \
                --add-module=modules/nginx-statsd-master \
                --add-module=modules/nginx-lambda"


RUN echo http://dl-4.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
    && apk --no-cache add ${build_pkgs} ${runtime_pkgs} \
    && echo 'cacert=/etc/ssl/certs/ca-certificates.crt' > ~/.curlrc \
    && echo 'capath=/etc/ssl/certs/' >> ~/.curlrc \
    && mkdir -p /etc/nginx/conf.d /var/cache/nginx /var/log/nginx /usr/share/nginx/html \
    && ln -sf /dev/stdout /var/log/nginx/error.log \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && rm -rf /var/cache/apk/*

RUN wget -O /tmp/nginx.tar.gz $NGINX_URL \
    && tar zxvf /tmp/nginx.tar.gz -C /tmp \
    && rm /tmp/nginx.tar.gz \
    && mv /tmp/nginx* /tmp/nginx \
    && mkdir -p /tmp/nginx/modules/nginx-lambda \
    && wget -O /tmp/nginx/modules/nginx-statsd.tar.gz https://github.com/zebrafishlabs/nginx-statsd/archive/master.tar.gz \
    && tar zxvf /tmp/nginx/modules/nginx-statsd.tar.gz -C /tmp/nginx/modules \
    && rm /tmp/nginx/modules/nginx-statsd.tar.gz
    
ADD config ngx_http_lambda_module.c /tmp/nginx/modules/nginx-lambda/

RUN cd /tmp/nginx \
    && ./configure ${NGINX_OPTS} \
    && make \
    && make install

CMD ["nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
ADD nginx.conf /etc/nginx/
