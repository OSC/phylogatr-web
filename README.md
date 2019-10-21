## Phylogatr

Prototype app using [GBIF occurrence download 0016052-190918142434337](https://www.gbif.org/occurrence/download/0016052-190918142434337)

Took the following steps to do a search for this download:

- ![gbif_search_0](doc/gbif_search_0.png)
- ![gbif_search_1](doc/gbif_search_1.png)
- ![gbif_search_2](doc/gbif_search_2.png)
- ![gbif_search_3](doc/gbif_search_3.png)

Install MUSCLE binary to bin/ using wget i.e.

    cd bin
    get http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
    tar -xzf muscle3.8.31_i86linux64.tar.gz
    rm muscle3.8.31_i86linux64.tar.gz

Install and use [Miller](https://github.com/johnkerl/miller) for parsing CSV (and tab delimited CSV files) first:

    cd ~/bin
    wget https://github.com/johnkerl/miller/releases/download/v5.6.2/mlr.linux.x86_64
    mv mlr.linux.x86_64 mlr
    chmod 755 mlr

Then can pre-parse the occurrence download for the relevant information:

    mlr --tsv cut -f gbifID,decimalLatitude,decimalLongitude,phylum,class,order,family,genus,species,associatedSequences db/seed_data/occurrence.txt | mlr --tsv filter '$associatedSequences !=~ "^[, ]*$"'


Some of the GBIF records have mismatched quotes. In that case we can try using
tsvlite:


    mlr --tsvlite cut -f gbifID,decimalLatitude,decimalLongitude,phylum,class,order,family,genus,species,associatedSequences db/seed_data/occurrence.txt | mlr --tsvlite filter '$associatedSequences !=~ "^[, ]*$"'

In the actual pipeline it is possible this tool could be used as part of a bash
pipeline to generate insert commands in to a database for each occurrence.


## License

To Be Determined!
