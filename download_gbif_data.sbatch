#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 30:00:00
#SBATCH --job-name="gbif_phylogatr_download"

set -xe

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

GBIF_URL="https://api.gbif.org/v1/occurrence/download/request/$GBIF_ID.zip"

wget "$GBIF_URL" -O "$PHYLOGATR_GBIF_DIR/$GBIF_ID.zip"
