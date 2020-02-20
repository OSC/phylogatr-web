#!/bin/bash

set -xe
set -o pipefail

time ./db_to_fasta_file.rb $1 | ../bin/muscle3.8.31_i86linux64 -quiet | ./aligned_fasta_to_db.rb


