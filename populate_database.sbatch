#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -t 06:00:00
#SBATCH --job-name="populate_db_phlyogatr"
#SBATCH --output=log/%x-%j.out

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

module load ruby/$PHYLOGATR_RUBY_VERSION

time bin/bundle exec bin/db populate development $WORKDIR/gbif.tsv
bin/rake metrics:populate_database
