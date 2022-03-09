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

id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.sbatch)
id=$(sbatch --dependency=afterok:${id##* } clean_database.sbatch)
id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.sbatch)

id=$(sbatch --dependency=afterok:${id##* } align.sbatch)
id=$(sbatch --dependency=afterok:${id##* } update_species_metrics.sbatch)

id=$(sbatch --dependency=afterok:${id##* } report_species_metrics.sbatch)
