#!/bin/bash

# $1 is like:
# /fs/project/PAS1604/bold/evocoidae.tsv

tsv="$(basename $1)"
time tail -n +2 $1 | cut -d $'\t' -f1,3,4,5,10,12,14,16,20,22,24,47,48,70,71,72 > $TMPDIR/$tsv

time GENBANK_ROOT=$TMPDIR/genes bin/rake pipeline:add_bold_records < $TMPDIR/$tsv 2>"$TMPDIR/$tsv.errors"
