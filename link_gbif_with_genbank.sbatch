#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=40
#SBATCH -t 12:00:00
#SBATCH --job-name="link_gbif_and_genbank"
#SBATCH --output=log/%x-%j.out

set -xe

cd $SLURM_SUBMIT_DIR
[ -f "$SLURM_SUBMIT_DIR/env" ] && source "$SLURM_SUBMIT_DIR/env"

# export GENBANK_DIR=/fs/project/PAS1604/genbank
# export GBIF_PATH=/fs/project/PAS1604/gbif/0147211-200613084148143.filtered.txt
    #  now PHYLOGATR_GBIF_FILTERED
# export GBIF_PATH_EXPANDED=/fs/project/PAS1604/gbif/0147211-200613084148143.filtered.txt.expanded
    #  now PHYLOGATR_GBIF_EXPANDED

module load pcp
module load ruby/$PHYLOGATR_RUBY_VERSION

function expand_gbif_occurrences {
    export GBIF_OUT="$TMPDIR/gbif_occurrences.csv"
    export GBIF_SORTED="$GBIF_OUT.sorted"

    if [[ -f $PHYLOGATR_GBIF_EXPANDED ]]; then
        echo "Using expanded GBIF file at $PHYLOGATR_GBIF_EXPANDED"
        cp "$PHYLOGATR_GBIF_EXPANDED" "$GBIF_SORTED"
    else
        # FIXME: if the expanded gbif file is not sorted, the linking of the two files will fail silently
        # either test and verify, and leave below as is
        # or change the expansion code to build the file in memory before writing or write to tmp file and then sort tmp to final dest
        bin/rake pipeline:expand_gbif_occurrences_on_accession GBIF=$PHYLOGATR_GBIF_FILTERED
        sort -k 1b,1 "$GBIF_OUT" > "$GBIF_SORTED"
        cp "$GBIF_SORTED" $PHYLOGATR_GBIF_EXPANDED
    fi
}

function link_occurrence_and_genes {
    export GBIF_PATH_EXPANDED=$TMPDIR/gbif_occurrences.csv.sorted
    TMP_SCRIPT=$(mktemp)

    # takes 20m - a lot of time lost in bin/rake setup - could switch this to bin/db or add a bin/pipeline thor script
    for i in $PHYLOGATR_GENBANK_DIR/gb{inv,mam,pln,pri,rod,vrt}*seq.gz
    do
        echo "OUTPUT_DIR=$TMPDIR GENBANK_PATH=$i bin/rake pipeline:link_gbif_with_genbank" >> "$TMP_SCRIPT"
    done

    srun -n $((`nproc`-1)) --export=ALL parallel-command-processor $TMP_SCRIPT

    # FIXME: parallelizing tasks doesn't work with multitask but may with https://github.com/grosser/parallel_tests
    # 38m on 40 items (so it really isn't doing parallelism (just using threads)
    # (time GBIF_PATH_EXPANDED=$TMPDIR/gbif_occurrences.csv.sorted OUTPUT_DIR=$TMPDIR bin/rake -m pipeline:link_gbif_with_genbank)
}

function collect_files {
    cat $TMPDIR/*.genes.tsv.occurrences > $TMPDIR/gbif.tsv
    cat $TMPDIR/*.genes.tsv > $TMPDIR/genes.tsv
}

function create_genes_directory {
    mkdir $TMPDIR/genes
    cat $TMPDIR/genes.tsv | ruby genes.rb $TMPDIR/genes
    (cd $TMPDIR; tar czf genes.tar.gz genes)
}

function copy_results_to_output_dir {
    cp $TMPDIR/genes.tar.gz $TMPDIR/genes.tsv $TMPDIR/gbif.tsv $WORKDIR
}

if [[ -f $WORKDIR/genes.tsv && -f $WORKDIR/gbif.tsv && -f $WORKDIR/genes.tar.gz ]]
then
    echo "Using already generated genes.tsv, gbif.tsv, and genes.tar.gz"
else
    time expand_gbif_occurrences
    time link_occurrence_and_genes
    time collect_files
    time create_genes_directory
    time copy_results_to_output_dir
fi
