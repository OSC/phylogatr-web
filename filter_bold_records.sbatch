#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=28
#SBATCH -t 01:00:00
#SBATCH --job-name="filter_bold_phylogatr"
#SBATCH --output=log/%x-%j.out

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
  time tail -n +2 $tsv | cut -d $'\t' -f1,3,4,5,10,12,14,16,20,22,24,47,48,70,71,72 >> $TMPDIR/bold.tsv
done

# sequential
# time bin/rake pipeline:filter_bold_records < $TMPDIR/bold.tsv >$TMPDIR/bold.tsv.filtered 2>$TMPDIR/bold.tsv.filtered.errors

# parallel
# NOTE: 14 not 28 because more than that puts too much load on MySQL
# this only takes 10 minutes anyways
split -d -n 14 $TMPDIR/bold.tsv $TMPDIR/x

for tsv in $TMPDIR/x*
do
  time bin/rake pipeline:filter_bold_records < $tsv >$tsv.filtered 2>$tsv.filtered.errors &
done
wait

# print out all errors with header per error file
echo "Errors:"
tail -n +1 $TMPDIR/*errors

cat $TMPDIR/*filtered > $TMPDIR/bold.tsv.filtered
cp $TMPDIR/bold.tsv.filtered $WORKDIR/bold.tsv
