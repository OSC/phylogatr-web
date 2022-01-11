#!/bin/bash
#SBATCH -t 10:00:00
#SBATCH --nodes 1
#SBATCH --exclusive
#SBATCH --job-name="gbif_no_location"
#SBATCH --output=log/%x-%j.out
#SBATCH --gres=pfsdir

set -xe
cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

module load ruby/$PHYLOGATR_RUBY_VERSION

split -d -n $(nproc) $PHYLOGATR_GBIF_RAW $PFSDIR/x

time bin/rake metrics:gbif_no_location["$PFSDIR/x"]
