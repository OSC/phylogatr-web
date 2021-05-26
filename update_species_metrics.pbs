#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=28
#SBATCH -t 04:00:00
#SBATCH --job-name="update_species_metrics_phylogatr"

set -xe

export WORKDIR=${WORKDIR:-/fs/project/PAS1604/pipeline/dev}

cd $SLURM_SUBMIT_DIR
module load ruby

cp $WORKDIR/genes.tar.gz $TMPDIR
time (cd $TMPDIR; tar xzf genes.tar.gz)

time GENBANK_ROOT=$TMPDIR/genes bin/rake pipeline:update_species_metrics
