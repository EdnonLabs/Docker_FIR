FROM alpine:3.8

MAINTAINER Rafael de Vega, rafael.devega@ednon.es

RUN apk add --update \
    gettext \
    python \
    python-dev \
    py-mysqldb \
    py-pip \
    build-base \
    py-lxml \
    git \
    libxml2 \
    libxml2-dev \
    libxslt \
    libxslt-dev \
    zlib-dev \
    mysql-client \
    wget \
    gcc \
    libc-dev \
    linux-headers \
    openssl \
    nginx

WORKDIR /app/

# prepare fir
RUN git clone https://github.com/certsocietegenerale/FIR.git && \
    cd FIR && \
    pip install -r requirements.txt && \
    pip install uwsgi && \
    mkdir run && \
    wget https://raw.githubusercontent.com/nginx/nginx/master/conf/uwsgi_params -P run && \
    cp fir/config/installed_apps.txt.sample fir/config/installed_apps.txt

# ensure www-data user exists
RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data

WORKDIR /app/FIR

COPY config/production.py /app/FIR/fir/config/production.py
COPY config/nginx.conf /etc/nginx/sites-available/fir
COPY config/fixtures/* /app/FIR/incidents/fixtures/
COPY config/entrypoint.sh /app/FIR/entrypoint.sh
RUN  chmod +x entrypoint.sh 

CMD [ "./entrypoint.sh" ]