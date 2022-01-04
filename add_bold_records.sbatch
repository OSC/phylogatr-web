#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=28
#SBATCH -t 01:30:00
#SBATCH --job-name="add_bold_phylogatr"
#SBATCH --output=log/%x-%j.out

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

set -xe

cp $WORKDIR/bold.tsv $TMPDIR
cp $WORKDIR/genes.tar.gz $TMPDIR
time (cd $TMPDIR; tar xzf genes.tar.gz)

if [[ "$PHYLOGATR_DATABASE_URL" == *sqlite3 ]]; then
  # serial
  time GENBANK_ROOT=$TMPDIR/genes bin/rake pipeline:add_bold_records < $TMPDIR/bold.tsv 2> $TMPDIR/bold.errors
else
  # parallel
  # NOTE: 14 not 28 because more than that puts too much load on MySQL
  # this only takes 10 minutes anyways
  split -d -n 14 $TMPDIR/bold.tsv $TMPDIR/x

  for tsv in $TMPDIR/x*
  do
    time GENBANK_ROOT=$TMPDIR/genes bin/rake pipeline:add_bold_records < $tsv 2>$tsv.errors &
  done
  wait

  # print out all errors with header per error file
  echo "Errors:"
  tail -n +1 $TMPDIR/*errors
fi


time (cd $TMPDIR; tar czf genes_with_bold.tar.gz genes)
cp $TMPDIR/genes_with_bold.tar.gz $WORKDIR/genes.tar.gz
