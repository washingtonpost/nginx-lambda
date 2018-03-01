FROM alpine:3.4
EXPOSE 8080

ENV NGINX_URL="http://nginx.org/download/nginx-1.10.2.tar.gz" \
    build_pkgs="build-base linux-headers openssl-dev pcre-dev zlib-dev wget curl py-pip" \
    runtime_pkgs="ca-certificates openssl pcre zlib dumb-init supervisor fabric" \
    NGINX_OPTS="--user=nginx \
                --group=nginx \
                --sbin-path=/usr/sbin/ \
                --prefix=/etc/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --http-log-path=/var/log/nginx/access.log \
                --add-module=modules/nginx-lambda"


RUN echo http://dl-4.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
    && apk --no-cache add ${build_pkgs} ${runtime_pkgs} \
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
    && mkdir -p /tmp/nginx/modules/nginx-lambda

ADD . /tmp/nginx/modules/nginx-lambda/

RUN cd /tmp/nginx \
    && ./configure ${NGINX_OPTS}

RUN cd /tmp/nginx \
    && make -j 2 \
    && make install

CMD ["nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
ADD nginx.conf /etc/nginx/
