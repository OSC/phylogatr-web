#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=28
#SBATCH -t 06:00:00
#SBATCH --job-name="add_bold_phylogatr"
#SBATCH --output=log/%x-%j.out
#SBATCH --gres=pfsdir

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

set -xe

BOLD_ROOT="$PFSDIR/bold"
mkdir -p "$BOLD_ROOT"

cp $WORKDIR/bold.tsv $PFSDIR
cp $WORKDIR/genes.tar.gz $PFSDIR
time (cd $PFSDIR; tar xzf genes.tar.gz)

if [[ "$PHYLOGATR_DATABASE_URL" == *sqlite3 ]]; then
  # serial
  mv "$PFSDIR/bold.tsv" "$BOLD_ROOT/bold.tsv"
  time BOLD_ROOT="$BOLD_ROOT" GENBANK_ROOT=$PFSDIR/genes bin/rake pipeline:add_bold_records
else
  # parallel
  # NOTE: 14 not 28 because more than that puts too much load on MySQL
  # this only takes 10 minutes anyways
  split -d --additional-suffix '.tsv' -n 14 $PFSDIR/bold.tsv $BOLD_ROOT/x

  BOLD_ROOT="$BOLD_ROOT" GENBANK_ROOT=$PFSDIR/genes bin/rake pipeline:add_bold_records

  # print out all errors with header per error file
  echo "Errors:"
  tail -n +1 $PFSDIR/*errors
fi


time (cd $PFSDIR; tar czf genes_with_bold.tar.gz genes)
cp $PFSDIR/genes_with_bold.tar.gz $WORKDIR/genes.tar.gz
