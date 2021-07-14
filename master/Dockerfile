FROM postgres:12.5
RUN chmod 777 /tmp
RUN apt-get update \
    && apt-get --assume-yes install iputils-ping \
    && apt-get install --assume-yes ssh \
    && apt-get install --assume-yes gosu
COPY ./setup-master.sh /docker-entrypoint-initdb.d/setup-master.sh
RUN chmod 0666 /docker-entrypoint-initdb.d/setup-master.sh
