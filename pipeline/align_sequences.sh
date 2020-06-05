#!/bin/bash

set -xe
set -o pipefail

# $1 is path to fasta file ending in .fa
fasta_file=$1
fasta_file_aligned="${fasta_file%.fa}.afa"
fasta_tmp="$TMPDIR/$(basename $fasta_file_aligned)"

function remove_newlines_in_fasta {
  ruby -ne 'print $_[0] == ">" ? "\n#{$_}" : $_.sub("\n","")' | ruby -e 'puts $stdin.read.strip'
}

function align {
  ../bin/mafft --adjustdirection --auto --inputorder --quiet $1
}

function trim {
  ../bin/trimal -in $1 -resoverlap 0.85 -seqoverlap 50 -gt 0.15
}

align $fasta_file > $fasta_tmp
trim $fasta_tmp | remove_newlines_in_fasta > $fasta_file_aligned
