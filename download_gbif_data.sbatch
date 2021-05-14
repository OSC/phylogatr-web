#!/bin/bash
#SBATCH --ntasks=1
#SBATCH -t 30:00:00
#SBATCH --job-name="gbif_phylogatr_download"

set -xe

cd /fs/project/PAS1604/gbif
wget https://api.gbif.org/v1/occurrence/download/request/0147211-200613084148143.zip
