#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 20:00:00
#SBATCH --job-name="phylogatr_download_bold_data"

set -xe

cd $SLURM_SUBMIT_DIR
module load ruby

bin/bundle exec bin/db download_all_bold /fs/project/PAS1604/bold
