#!/bin/bash
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH -t 40:00:00
#SBATCH --job-name="align_phylogatr"
#SBATCH --output=log/%x-%j.out

set -xe

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

module load ruby/$PHYLOGATR_RUBY_VERSION
module load pcp

# if you want to set a timeout for alignments, this is a way to ensure the majority of alignments
# will get done in a timely manner, and then you can resubmit a job without the timelimit
#
#    export TIMEOUT=10m
#
# or
#
#    export TIMEOUT=60m

# copy genes tarball to TMPDIR
cp $WORKDIR/genes.tar.gz $TMPDIR
time (cd $TMPDIR; tar xzf genes.tar.gz)

GENBANK_ROOT=$TMPDIR/genes bin/rake pipeline:align


# tar up genes with alignments and copy back
time (cd $TMPDIR; tar czf genes_with_alignments.tar.gz genes)
cp $TMPDIR/genes_with_alignments.tar.gz $WORKDIR/genes.tar.gz
