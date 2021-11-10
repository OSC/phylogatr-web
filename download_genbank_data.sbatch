#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 72:00:00
#SBATCH --job-name=genbank_update

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

mkdir -p "$PHYLOGATR_GENBANK_DIR"
cd "$PHYLOGATR_GENBANK_DIR"

# rsync was here initially, but stopped working after some time.
wget -m -nH --cut-dirs=1 'ftp://ftp.ncbi.nlm.nih.gov/genbank'

gunzip *.gz
ls *.tar | xargs -i tar xf {}
