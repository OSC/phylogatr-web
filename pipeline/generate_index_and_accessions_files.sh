#!/bin/bash

occurrences_file=$1
genbank_file=$2
output_dir=$3

index_path=$(invoke make-index $genbank_file $output_dir)
join -t $'\t' $1 <(sqlite3  $index_path 'select key from offset_data  order by key asc') | ../bin/bundle exec rake pipeline:filter_occurrences > "${index_path}.occurrences"

echo "generated index and accessions file for $genbank_file"
