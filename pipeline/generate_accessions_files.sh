#!/bin/bash

occurrences_file=$1
index_path=$2
output_dir=$3

output_file="${index_path}.occurrences"

echo "generating $output_file..."
time join -t $'\t' $1 <(sqlite3  $index_path 'select key from offset_data  order by key asc') | ../bin/bundle exec rake pipeline:filter_occurrences > $output_file

echo "done generating $output_file"
