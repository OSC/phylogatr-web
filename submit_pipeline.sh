#!/bin/bash

if [ ! -f "$PWD/env" ]; then
  echo '$PWD needs to be in the same directory as this file'
  exit 1
else
  source "$PWD/env"
fi

echo "using workdir: $WORKDIR"

# creates genes.tsv, gbif.tsv, genes.tar.gz
id=$(sbatch link_gbif_with_genbank.sbatch)

# populates database from gbif.tsv
id=$(sbatch --dependency=afterok:${id##* } populate_database.sbatch)

# creates bold.tsv
id=$(sbatch --dependency=afterok:${id##* } filter_bold_records.sbatch)

# populates database from bold.tsv and adds new files or sequences to existing files in genes.tar.gz
id=$(sbatch --dependency=afterok:${id##* } add_bold_records.sbatch)

id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.pbs)
id=$(sbatch --dependency=afterok:${id##* } clean_database.pbs)
id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.pbs)

# FIXME: if executing this job alignment without TIMEOUT and no genes.db cache file this job will likely exceed
# the walltime and fail; since the copy back to project is done at the end,
# if the walltime kills an alignment job all work is lost
#
# consider adding logic here to determine if alignment cache is available,
# if not run align.pbs three times, first with a timeout of 10m, second with 60m and finally without a timeout,
# copying results back in between; or add logic here and submit align.pbs several times with different timeouts
id=$(sbatch --dependency=afterok:${id##* } align.pbs)
id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.pbs)
id=$(sbatch --dependency=afterok:${id##* } update_alignment_cache.pbs)

id=$(sbatch --dependency=afterok:${id##* } report_species_metrics.pbs)
