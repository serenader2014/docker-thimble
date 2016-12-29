FROM node:4.4.4
MAINTAINER serenader xyslive@gmail.com

RUN apt-get update && apt-get install -y build-essential postgresql-9.4 postgresql-client-9.4 \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/thimble

RUN git clone --depth 1 https://github.com/mozilla/brackets.git \
    && cd brackets && git submodule update --init \
    && npm install && npm run build

RUN git clone --depth 1 https://github.com/mozilla/thimble.mozilla.org.git \
    && cd thimble.mozilla.org && cp env.dist .env \
    && npm install && npm run localize

RUN git clone --depth 1 https://github.com/mozilla/id.webmaker.org.git \
    && cd id.webmaker.org && cp sample.env .env \
    && npm install

RUN git clone --depth 1 https://github.com/mozilla/login.webmaker.org.git \
    && cd login.webmaker.org && npm install && cp env.sample .env

RUN git clone --depth 1 https://github.com/mozilla/publish.webmaker.org.git \
    && cd publish.webmaker.org && npm install && npm run env \
    && npm install -g knex

COPY start.sh /var/thimble/start.sh

CMD ["/bin/bash", "/var/thimble/start.sh"]
