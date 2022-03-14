#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -t 02:00:00
#SBATCH --job-name="clean_database"
#SBATCH --output=log/%x-%j.out

set -xe

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

cp $WORKDIR/genes.tar.gz $TMPDIR
time (cd $TMPDIR; tar xzf genes.tar.gz)

# clean database after deleting files
time GENBANK_ROOT=$TMPDIR/genes bin/rake pipeline:clean_db

# copy modified genes.tar.gz back

time (cd $TMPDIR; tar czf genes2.tar.gz genes)
cp $TMPDIR/genes2.tar.gz $WORKDIR/genes.tar.gz
