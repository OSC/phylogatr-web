#!/bin/bash

export WORKDIR=${WORKDIR:-/fs/project/PAS1604/pipeline/dev}
echo "using workdir: $WORKDIR"

# creates genes.tsv, gbif.tsv, genes.tar.gz
id=$(sbatch link_gbif_with_genbank.pbs)

# populates database from gbif.tsv
id=$(sbatch --dependency=afterok:${id##* } populate_database.pbs)

# creates bold.tsv
id=$(sbatch --dependency=afterok:${id##* } filter_bold_records.pbs)

# populates database from bold.tsv and adds new files or sequences to existing files in genes.tar.gz
id=$(sbatch --dependency=afterok:${id##* } add_bold_records.pbs)

id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.pbs)
id=$(sbatch --dependency=afterok:${id##* } clean_database.pbs)
id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.pbs)

id=$(sbatch --dependency=afterok:${id##* } align.pbs)
id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.pbs)
id=$(sbatch --dependency=afterok:${id##* } update_alignment_cache.pbs)

id=$(sbatch --dependency=afterok:${id##* } report_species_metrics.pbs)
