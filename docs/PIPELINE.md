# Data Pipeline

These are steps to create the data pipeline used in this app and ultimately
the database it reads from.

The pipeline scripts are `sbatch` files meant to run in Slurm.
If you're using a different scheduler the `#SBATCH` directives won't work for you.

It's very important that you submit jobs from this projects' root directory.
In Slurm we use `$SLURM_SUBMIT_DIR` to source the [environment file](../env)
of this project.  For this to work you must run `sbatch` from the root directory
of this project.  

Other schedulers need to replicate this pattern to make use of environment variables
to change locations of data files.

## Download Raw data

First you need to get the raw data from other sources.

These scripts download all the data required.

```
download_bold_data.sbatch
download_gbif_data.sbatch
download_genbank_data.sbatch
```

Here's a simple override file to download all this data, which totals just under 4 terabytes, into your
home.

```bash
# downloads just less than 4TB 
BASE_DIR="$HOME/phylogatr"
RAW_DIR="$BASE_DIR/raw"

export WORKDIR="$BASE_DIR/pipeline"
export PHYLOGATR_BOLD_DIR="$RAW_DIR/bold"
export PHYLOGATR_GBIF_DIR="$RAW_DIR/gbif"
export PHYLOGATR_GENBANK_DIR="$RAW_DIR/genbank"
export PHYLOGATR_RUBY_VERSION="$RUBY_VERSION"
```

These scripts can be very slow, so please allow for some time to pass for these things
to download.

### Filter Gbif Data

First, we need to unzip and filter GBIF data. These 2 scripts do that.

Unzipping will unzip `$PHYLOGATR_GBIF_DIR/$PHYLOGATR_GBIF_ID.zip` to
a 1.7 TB file `$PHYLOGATR_GBIF_DIR/occurrences.txt` ( or `PHYLOGATR_GBIF_RAW`).

We then filter this file into `$PHYLOGATR_GBIF_DIR/occurrences.txt.filtered` (or
`$PHYLOGATR_GBIF_FILTERED`). We remove records that do not have any `associatedSequences`
or do not have all 249 fields.

```
gbif_unzip.sbatch
gbif_filter_occurrences.sbatch
```

## Link GBIF data with Genbank

The script [link_gbif_with_genbank.sbatch](../link_gbif_with_genbank.sbatch)
will link GBIF data with Genbank and starts the pipeline.

When this job is complete you should see the beginnings of the pipeline in
the `WORKDIR` environment variable, like so:

```
[johrstrom phylogatr(link-gbif)] 🐻  ls $WORKDIR -lrt
total 1940576
-rw-r--r-- 1 johrstrom PZS0714   93992551 Nov 19 11:09 genes.tar.gz
-rw-r--r-- 1 johrstrom PZS0714 1116367020 Nov 19 11:09 genes.tsv
-rw-r--r-- 1 johrstrom PZS0714  776777918 Nov 19 11:09 gbif.tsv
```