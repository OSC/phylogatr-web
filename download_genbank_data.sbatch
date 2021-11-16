#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 72:00:00
#SBATCH --job-name=genbank_update
#SBATCH --output=log/%x-%j.out

module purge

set -x
cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"
set +x

module load ruby/$PHYLOGATR_RUBY_VERSION

mkdir -p "$PHYLOGATR_GENBANK_DIR"

bin/bundle exec bin/db download_genbank $PHYLOGATR_GENBANK_DIR
# ruby dl_genbank.rb

# cd "$PHYLOGATR_GENBANK_DIR"
# gunzip *.gz
# ls *.tar | xargs -i tar xf {}

# I'm leaving all of these here out of frustration. Or at least so
# they're in the mainline for a while (if anyone happens upon them).
# FIXME: very slow
# wget -m -nH --cut-dirs=1 'ftp://ftp.ncbi.nlm.nih.gov/genbank'

# rsync isn't working for me at the moment
# rsync \
#   --copy-links --recursive \
#   --times --verbose --exclude wgs \
#   rsync://ftp.ncbi.nlm.nih.gov/genbank \
#

# rsync -zvvv \
#   --recursive \
#   --progress \
#   -e ssh
#   -f"- */" -f"+ *" \
#   'rsync://ftp.ncbi.nlm.nih.gov/genbank' \
#   $PHYLOGATR_GENBANK_DIR

# rclone \
#   --copy-links --recursive \
#   --times --verbose --exclude wgs \
#   rsync://ftp.ncbi.nlm.nih.gov/genbank \
#   $PHYLOGATR_GENBANK_DIR 

