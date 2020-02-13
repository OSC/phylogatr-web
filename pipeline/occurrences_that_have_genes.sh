#!/bin/bash

occurrences_file=$1
gene_file=$2

join -t $'\t' $1 <(awk '{ print $1 }' $gene_file | sort | uniq) > "${occurrences_file}.with_genes"
