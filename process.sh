#!/bin/bash

set -e

echo "process started"
echo "Start: obask-pipeline-updatesolr"
echo "OBASKTIME:"
date

DATA=/data/dumps
host=solr
port=8983
collection=ontology

if [ `ls $DATA/solr.json | wc -l` -lt 1 ]; then echo "ERROR: No solr.json in data directory! Aborting.. " && exit 1; fi

cd $DATA

echo "Indexing $collection in server $host:$port"
curl --location --request POST "http://$host:$port/solr/$collection/update/json?commit=true" --header 'Content-Type: application/json' --data-binary '@solr.json'

echo "Initializing schema for $collection collection in server $host:$port"
bash /updatesolr/solr_schema_initializer.sh -h $host -p $port -c $collection

echo "Re-indexing $collection in server $host:$port"
curl --location --request POST "http://$host:$port/solr/$collection/update/json?commit=true" --header 'Content-Type: application/json' --data-binary '@solr.json'


echo "End: obaskb-pipeline-updatesolr"
echo "OBASKTIME:"
date
echo "process complete"
