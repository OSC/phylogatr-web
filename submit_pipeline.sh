#!/bin/bash

id=$(sbatch populate_database.pbs)
id=$(sbatch --dependency=afterany:${id##* } filter_bold_records.pbs)
id=$(sbatch --dependency=afterany:${id##* } add_bold_records.pbs)

id=$(sbatch --dependency=afterany:${id##* } update_species_metrics.pbs)
id=$(sbatch --dependency=afterany:${id##* } align.pbs)
id=$(sbatch --dependency=afterany:${id##* } update_species_metrics.pbs)
