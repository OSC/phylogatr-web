#!/bin/bash
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH -t 01:00:00
#SBATCH --job-name="filter_bold_phylogatr"
#SBATCH --output=log/%x-%j.out
#SBATCH --gres=pfsdir

set -x

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

module load ruby/$PHYLOGATR_RUBY_VERSION

# 1   processid
# 3   recordID
# 4   catalognum
# 5   fieldnum
# 10  phylum_name
# 12  class_name
# 14  order_name
# 16  family_name
# 18  subfamily_name
# 20  genus_name
# 22  species_name
# 24  subspecies_name
# 47  lat
# 48  lon
# 70  markercode
# 71  genbank_accession
# 72  nucleotides

for tsv in $PHYLOGATR_BOLD_DIR/*tsv; do
  time tail -n +2 $tsv | cut -d $'\t' -f1,3,4,5,10,12,14,16,20,22,24,47,48,70,71,72 >> $PFSDIR/bold.tsv
done

# sequential
# time bin/rake pipeline:filter_bold_records < $PFSDIR/bold.tsv >$PFSDIR/bold.tsv.filtered 2>$PFSDIR/bold.tsv.filtered.errors

# parallel
# NOTE: 14 not 28 because more than that puts too much load on MySQL
# this only takes 10 minutes anyways
split -d -n $(nproc) $PFSDIR/bold.tsv $PFSDIR/x

FILTERED_BOLD_DIR=$PFSDIR \
  OUTPUT_FILE="$PFSDIR/bold.tsv.filtered" \
  time bin/rake pipeline:filter_bold_records

cat $PFSDIR/x*.filtered > $PFSDIR/bold.tsv.filtered
ls -lrt $PFSDIR
cp $PFSDIR/bold.tsv.filtered $WORKDIR/bold.tsv
