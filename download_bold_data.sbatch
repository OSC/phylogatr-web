#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 20:00:00
#SBATCH --job-name="phylogatr_download_bold_data"
#SBATCH --output=log/%x-%j.out

set -xe

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

cd $SLURM_SUBMIT_DIR
module load ruby/$PHYLOGATR_RUBY_VERSION

bin/bundle exec bin/db download_all_bold $PHYLOGATR_BOLD_DIR
