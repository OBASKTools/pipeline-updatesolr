#!/usr/bin/env bash
#
# This script updates ontology schema with ngram based new search fields. These new text fields has naming: *_autosuggest_e,
# *_autosuggest_se, *_autosuggest_ne and *_autosuggest_ts, and enable partial matching capability. To run this script, 
# your solr should be up and running and the latest dump file, solr.json, is uploaded.
#
# Important: After the schema change, reindexing is required. For this purpose, you can simply re-upload the dump data
# to the ontology collection.
#
# Usage:
# bash solr_post_config.sh -h localhost -p 8993

set -e

autocomplete_single_val_fields=(label)
autocomplete_multi_val_fields=(synonym_hasExactSynonym synonym_hasNarrowSynonym synonym_hasBroadSynonym)

autocomplete_fields=("${autocomplete_single_val_fields[@]}" "${autocomplete_multi_val_fields[@]}")

while getopts h:p:c: flag
do
    case "${flag}" in
        h) host=${OPTARG};;
        p) port=${OPTARG};;
        c) collection=${OPTARG};;
        *) echo "!!! Invalid flag. Only -h and -p flags are supported."
    esac
done

echo "Updating $collection in server $host:$port"

echo "Adding texEdge field type"
curl -X POST -H 'Content-type:application/json' --data-binary "{
  \"add-field-type\":{
    \"name\":\"textEdge\",
    \"class\":\"solr.TextField\",
    \"indexAnalyzer\":{
      \"tokenizer\":{
         \"class\":\"solr.StandardTokenizerFactory\" },
       \"filters\":[{\"class\":\"solr.WordDelimiterGraphFilterFactory\",
                     \"splitOnCaseChange\":\"0\"},
                    {\"class\":\"solr.LowerCaseFilterFactory\"},
                    {\"class\":\"solr.EdgeNGramFilterFactory\",
                     \"minGramSize\":\"2\",
                     \"maxGramSize\":\"35\"}]
    },
    \"queryAnalyzer\":{
      \"tokenizer\":{
         \"class\":\"solr.WhitespaceTokenizerFactory\" },
       \"filters\":[{\"class\":\"solr.WordDelimiterGraphFilterFactory\",
                     \"splitOnCaseChange\":\"0\"},
		    {\"class\":\"solr.EnglishMinimalStemFilterFactory\"},
                    {\"class\":\"solr.LowerCaseFilterFactory\"}]
    }
  }
}" http://$host:$port/solr/$collection/schema --show-error --fail

echo "Adding textShingleEdge field type"
curl -X POST -H 'Content-type:application/json' --data-binary "{
  \"add-field-type\":{
    \"name\":\"textShingleEdge\",
    \"class\":\"solr.TextField\",
    \"indexAnalyzer\":{
      \"tokenizer\":{
         \"class\":\"solr.StandardTokenizerFactory\" },
       \"filters\":[{\"class\":\"solr.ShingleFilterFactory\",
                     \"maxShingleSize\":\"4\",
                     \"outputUnigrams\":\"false\"},
                   {\"class\":\"solr.LowerCaseFilterFactory\" },
                   {\"class\":\"solr.RemoveDuplicatesTokenFilterFactory\"}]
    },
    \"queryAnalyzer\":{
      \"tokenizer\":{
         \"class\":\"solr.KeywordTokenizerFactory\" },
       \"filters\":[{\"class\":\"solr.LowerCaseFilterFactory\" },
                   {\"class\":\"solr.RemoveDuplicatesTokenFilterFactory\"}]
    }
  }
}" http://$host:$port/solr/$collection/schema --show-error --fail

echo "Adding nameExact field type"
curl -X POST -H 'Content-type:application/json' --data-binary "{
  \"add-field-type\":{
    \"name\":\"nameExact\",
    \"class\":\"solr.TextField\",
    \"indexAnalyzer\":{
      \"tokenizer\":{
         \"class\":\"solr.KeywordTokenizerFactory\"},
       \"filters\":[{\"class\":\"solr.LowerCaseFilterFactory\" },
                   {\"class\":\"solr.RemoveDuplicatesTokenFilterFactory\"}]
    },
    \"queryAnalyzer\":{
      \"tokenizer\":{
         \"class\":\"solr.KeywordTokenizerFactory\" },
       \"filters\":[{\"class\":\"solr.LowerCaseFilterFactory\"},
                   {\"class\":\"solr.RemoveDuplicatesTokenFilterFactory\" }]
    }
  }  
}" http://$host:$port/solr/$collection/schema --show-error --fail

echo "Adding textStart field type"
curl -X POST -H 'Content-type:application/json' --data-binary "{
  \"add-field-type\":{
    \"name\":\"textStart\",
    \"class\":\"solr.TextField\",
    \"indexAnalyzer\":{
      \"tokenizer\":{
         \"class\":\"solr.KeywordTokenizerFactory\"},
       \"filters\":[{\"class\":\"solr.LowerCaseFilterFactory\" },
                   {\"class\":\"solr.RemoveDuplicatesTokenFilterFactory\"},
                   {\"class\":\"solr.EdgeNGramFilterFactory\",
                   \"minGramSize\":\"3\",
                   \"maxGramSize\":\"35\"}]
    },
    \"queryAnalyzer\":{
      \"tokenizer\":{
         \"class\":\"solr.KeywordTokenizerFactory\" },
       \"filters\":[{\"class\":\"solr.LowerCaseFilterFactory\"},
                   {\"class\":\"solr.RemoveDuplicatesTokenFilterFactory\"}]
    }
  }
}" http://$host:$port/solr/$collection/schema --show-error --fail

echo "Adding auto complete single value fields: ${autocomplete_single_val_fields[*]}"
for field in "${autocomplete_single_val_fields[@]}"; do

  echo "Adding auto complete field e: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-field\":{
       \"name\":\"${field}_autosuggest_e\",
       \"type\":\"textEdge\",
       \"indexed\":true,
       \"stored\":true,
       \"multiValued\":false
     }
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Adding auto complete field se: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-field\":{
       \"name\":\"${field}_autosuggest_se\",
       \"type\":\"textShingleEdge\",
       \"indexed\":true,
       \"stored\":true,
       \"multiValued\":false
     }
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Adding auto complete field ne: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-field\":{
       \"name\":\"${field}_autosuggest_ne\",
       \"type\":\"nameExact\",
       \"indexed\":true,
       \"stored\":true,
       \"multiValued\":false
     }
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Adding auto complete field ts: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-field\":{
       \"name\":\"${field}_autosuggest_ts\",
       \"type\":\"textStart\",
       \"indexed\":true,
       \"stored\":true,
       \"multiValued\":false,
       \"omitNorms\":false
     }
  }" http://$host:$port/solr/$collection/schema --show-error --fail

done

echo "Adding auto complete multi value fields: ${autocomplete_multi_val_fields[*]}"
for field in "${autocomplete_multi_val_fields[@]}"; do

  echo "Adding auto complete field e: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-field\":{
       \"name\":\"${field}_autosuggest_e\",
       \"type\":\"textEdge\",
       \"indexed\":true,
       \"stored\":true,
       \"multiValued\":true
     }
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Adding auto complete field se: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-field\":{
       \"name\":\"${field}_autosuggest_se\",
       \"type\":\"textShingleEdge\",
       \"indexed\":true,
       \"stored\":true,
       \"multiValued\":true
     }
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Adding auto complete field ne: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-field\":{
       \"name\":\"${field}_autosuggest_ne\",
       \"type\":\"nameExact\",
       \"indexed\":true,
       \"stored\":true,
       \"multiValued\":true
     }
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Adding auto complete field ts: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-field\":{
       \"name\":\"${field}_autosuggest_ts\",
       \"type\":\"textStart\",
       \"indexed\":true,
       \"stored\":true,
       \"multiValued\":true,
       \"omitNorms\":false
     }
  }" http://$host:$port/solr/$collection/schema --show-error --fail

done

echo "Copying auto complete fields: ${autocomplete_fields[*]}"
for field in "${autocomplete_fields[@]}"; do

  echo "Copying auto complete field e: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-copy-field\":{
    \"source\":\"${field}\",
    \"dest\":\"${field}_autosuggest_e\"}
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Copying auto complete field se: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-copy-field\":{
    \"source\":\"${field}\",
    \"dest\":\"${field}_autosuggest_se\"}
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Copying auto complete field ne: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-copy-field\":{
    \"source\":\"${field}\",
    \"dest\":\"${field}_autosuggest_ne\"}
  }" http://$host:$port/solr/$collection/schema --show-error --fail

  echo "Copying auto complete field ts: ${field}"
  curl -X POST -H 'Content-type:application/json' --data-binary "{
    \"add-copy-field\":{
    \"source\":\"${field}\",
    \"dest\":\"${field}_autosuggest_ts\"}
  }" http://$host:$port/solr/$collection/schema --show-error --fail

done

echo "successfully finished configuring solr schema with the Schema API."
echo "SUCCESS"
