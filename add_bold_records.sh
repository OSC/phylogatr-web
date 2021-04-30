#!/bin/bash

set -xe

cd $SLURM_SUBMIT_DIR

# copy genes tarball to TMPDIR
cp /fs/project/PAS1604/pipeline/dev/genes.tar.gz $TMPDIR
time (cd $TMPDIR; tar xzf genes.tar.gz)

# add bold data to database and $TMPDIR/genes
module load ruby
module load pcp

for tsv in "$@"
do
  echo "./add_bold_records_from_tsv.sh $tsv" >> $TMPDIR/cmds
done

srun parallel-command-processor $TMPDIR/cmds


# print out all errors with header per error file
echo "Errors:"
tail -n +1 $TMPDIR/*errors

# tar up genes with bold data and copy back
time (cd $TMPDIR; tar czf genes_with_bold.tar.gz genes)
cp $TMPDIR/genes_with_bold.tar.gz /fs/project/PAS1604/pipeline/dev/
