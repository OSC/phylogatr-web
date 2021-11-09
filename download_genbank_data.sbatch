#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 15:00:00
#SBATCH --job-name=genbank_update

PHYLOGATR_GENBANK_DIR="${PHYLOGATR_GENBANK_DIR:=/fs/project/PAS1604/genbank}"

cd $PHYLOGATR_GENBANK_DIR
rsync \
  --copy-links --recursive \
  --times --verbose --exclude wgs \
  rsync://ftp.ncbi.nlm.nih.gov/genbank \
  $PHYLOGATR_GENBANK_DIR 

gunzip *.gz
ls *.tar | xargs -i tar xf {}
