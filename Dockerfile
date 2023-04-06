FROM ubuntu:latest

RUN apt-get -qq update || apt-get -qq update && apt-get -qq -y install curl

RUN mkdir /data
WORKDIR /updatesolr

COPY process.sh process.sh
COPY solr_schema_initializer.sh solr_schema_initializer.sh

RUN chmod +x *.sh

CMD ["./process.sh"]
