#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 30:00:00
#SBATCH --job-name="gbif_phylogatr_download"

set -xe

GBIF_ID="${GBIF_ID:-0147211-200613084148143}"
GBIF_URL="https://api.gbif.org/v1/occurrence/download/request/$GBIF_ID.zip"
PHYLOGATR_GBIF_DIR="${PHYLOGATR_GBIF_DIR:=.}"

cd $SLURM_SUBMIT_DIR

wget "$GBIF_URL" -O "$PHYLOGATR_GBIF_DIR/$GBIF_ID.zip"
