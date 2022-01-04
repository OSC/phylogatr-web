#!/bin/bash
#SBATCH --tasks=1
#SBATCH -t 20:00:00
#SBATCH --job-name="unzip_phylogatr"

# this took 03:25:13 to unzip occurrence.txt a 1.7T file

set -xe

cd "$SLURM_SUBMIT_DIR"
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

cd "$PHYLOGATR_GBIF_DIR"
cp "$PHYLOGATR_GBIF_ID.zip" $TMPDIR/gbif.zip

# TODO: find out, is this all we need from gbif?
cd $TMPDIR
time unzip gbif.zip citations.txt metadata.xml meta.xml rights.txt occurrence.txt
cp citations.txt metadata.xml meta.xml rights.txt occurrence.txt $PHYLOGATR_GBIF_DIR
