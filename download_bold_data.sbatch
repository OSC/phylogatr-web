#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 20:00:00
#SBATCH --job-name="phylogatr_download_bold_data"

set -xe

PHYLOGATR_BOLD_DIR="${PHYLOGATR_BOLD_DIR:-/fs/project/PAS1604/bold}"
PHYLOGATR_RUBY_VERSION="${PHYLOGATR_RUBY_VERSION:-2.5.5}"

cd $SLURM_SUBMIT_DIR
module load ruby/$PHYLOGATR_RUBY_VERSION

bin/bundle exec bin/db download_all_bold $PHYLOGATR_BOLD_DIR
