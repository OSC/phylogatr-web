#!/bin/bash
#SBATCH --exclusive
#SBATCH -t 10:00:00
#SBATCH --job-name="gbif_filter_occurrences"
#SBATCH --output=log/%x-%j.out
#SBATCH --gres=pfsdir

# this took 1:07 to process 1.7T of data
# run on occurrence.txt from 0147211-200613084148143.zip
set -xe
cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

module load ruby/$PHYLOGATR_RUBY_VERSION

time split -d -n $(nproc) $PHYLOGATR_GBIF_RAW $PFSDIR/x

# 249 is the number of columns created from a gbif search
# 84 is the column number (starting from 1) that is "associatedSequences"
#
#
# 84   associatedSequences
# 1    gbifID
# 133  decimalLatitude
# 134  decimalLongitude
# 191  kingdom
# 192  phylum
# 193  class
# 194  order
# 195  family
# 196  genus
# 230  species
# 199  infraspecificEpithet
# 135  coordinateUncertaintyInMeters
# 64   basisOfRecord
# 216  issue
# 98   fieldNumber
# 69   catalogNumber
# 27   identifier
# 99   eventDate

cd $PFSDIR

pids=()
for i in x*; do
  awk -F$'\t' 'BEGIN {OFS = FS} { if (NF==249 && $84 != "") print $84, $1, $133, $134, $191, $192, $193, $194, $195, $196, $230, $199, $135, $64, $216, $98, $69, $27, $99 }' $i > filtered.$i &
  pids+=($!)
done
wait "${pids[@]}"

cat filtered.* > "$PHYLOGATR_GBIF_FILTERED"

cd $SLURM_SUBMIT_DIR
time bin/rake metrics:gbif_filter_occurrences