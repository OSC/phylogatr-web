#!/bin/bash

export PROJ=/fs/project/PAS1604/pipeline/dev
cp $PROJ/stage-1/genes.tar.gz $PROJ/genes.tar.gz

id=$(sbatch populate_database.pbs)
id=$(sbatch --dependency=afterany:${id##* } filter_bold_records.pbs)
id=$(sbatch --dependency=afterany:${id##* } add_bold_records.pbs)

id=$(sbatch --dependency=afterany:${id##* } update_species_metrics.pbs)
id=$(sbatch --dependency=afterany:${id##* } align.pbs)
id=$(sbatch --dependency=afterany:${id##* } update_species_metrics.pbs)
id=$(sbatch --dependency=afterany:${id##* } clean_database.pbs)
id=$(sbatch --dependency=afterany:${id##* } update_species_metrics.pbs)
id=$(sbatch --dependency=afterany:${id##* } report_species_metrics.pbs)
id=$(sbatch --dependency=afterany:${id##* } update_alignment_cache.pbs)
