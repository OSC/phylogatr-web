## Phylogatr

### Install

Clone app

    git clone ... app
    cd app

Add to .bashrc

    export PATH=$HOME/bin:$PATH
    source scl_source enable rh-ruby25 rh-nodejs10

Then source .bashrc: `source ~/.bashrc`

Install bundler

    gem install --user bundler -v 1.17.3

Install gems

    bin/bundle install --path vendor/bundle # scls for ruby and devel required

Compile assets

    RAILS_ENV=production bin/rake assets:precompile

Add .env.production with database connection information and chmod 600



### Pipeline steps

#### 1. Download nucleotide database

In this case, we use a job `/fs/project/PAS1604/genbank/genbank_rsync.pbs`
(locally versioned in `pipeline/genbank_rsync.pbs`) to rsync all the data from
genbank ftp and expand all the .gz and .tar files in the base di /fs/project/PAS1604/genbank

gbrel.txt contains the Flat File Release number (in this case 234.0)

#### 2. Download occurrences database

GBIF provides a custom download https://zenodo.org/record/3531675
(eric_accession.zip) with columns:

- associatedSequences - accession ID column has many of the IDs wrapped in a URL. Also it can have multiple IDs separated by a | “pipe char”.
- gbifID
- decimalLatitude
- decimalLongitude
- kingdom
- phylum,
- class
- order
- family
- genus
- species
- infraspecificEpithet
- basisOfRecord,
- v_geodeticdatum
- coordinateuncertaintyinmeters
- issue

Copied to /fs/project/PAS1604/gbif_zenodo_3531675.csv

For citation purposes, the DOI of this download is to be used: 10.35000/cdl.t4hfxk.

Any columns with the string `\N` should be interpreted as NULL.

## See wiki for more information

- https://code.osu.edu/phylogatr/phylogatr/wikis

## License

To Be Determined!
