#!/bin/bash

set -x
set -o pipefail

# $1 is path to fasta file ending in .fa
fasta_file=$1
fasta_file_aligned="${fasta_file%.fa}.afa"

function remove_newlines_in_fasta {
  bin/seqkit seq -i -w0
}

function align {
  bin/mafft --adjustdirection --auto --inputorder --quiet $1
}

function trim {
  bin/trimal -in $1 -resoverlap 0.85 -seqoverlap 50 -gt 0.15
}

# trimal was throwing errors when doing in a single pipeline:
#
#     align $fasta_file |  trim /dev/stdin > $fasta_file_aligned
#
# so below uses an intermediate file to ensure alignment completes before trimal begins
fasta_tmp="$(mktemp)"
align $fasta_file > $fasta_tmp
trim $fasta_tmp | remove_newlines_in_fasta > $fasta_file_aligned

rm $fasta_tmp
