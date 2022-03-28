#!/bin/bash
#SBATCH --exclusive
#SBATCH -t 10:00:00
#SBATCH --job-name="filter_gbif_occurrences"
#SBATCH --output=log/%x-%j.out
#SBATCH --gres=pfsdir

# this took 1:07 to process 1.7T of data
# run on occurrence.txt from 0147211-200613084148143.zip
set -xe
cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

module load ruby/$PHYLOGATR_RUBY_VERSION

split_filter () { { head -n 1 $PHYLOGATR_GBIF_RAW; cat; } > "$FILE"; }
export -f split_filter

# takes about 30 minutes just to split
time split -d -n $(nproc) --filter=split_filter $PHYLOGATR_GBIF_RAW $PFSDIR/x

FILTERED_GBIF_DIR=$PFSDIR bin/rake pipeline:filter_gbif_records

cd $PFSDIR
cat *.filtered > "$PHYLOGATR_GBIF_FILTERED"
