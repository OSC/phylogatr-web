#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -t 01:00:00
#SBATCH --job-name="phylogatr_update_alignment_metrics"
#SBATCH --output=log/%x-%j.out

set -xe

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

module load ruby/$PHYLOGATR_RUBY_VERSION

cp $WORKDIR/genes.tar.gz $TMPDIR
time (cd $TMPDIR; tar xzf genes.tar.gz)

if [[ -e $WORKDIR/genes.db ]]; then
  cp $WORKDIR/genes.db $TMPDIR
fi

time ./generate_alignment_cache.rb $TMPDIR/genes $TMPDIR/genes.db

cp $TMPDIR/genes.db $WORKDIR/genes.db
