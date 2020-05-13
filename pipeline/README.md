### For pipeline

Create new conda env:

    module load python/3.6-conda5.2
    conda create -n local python=3.6

Install required packages:

    conda install -c conda-forge biopython
    conda install invoke

Not sure if I could do this unless I can omit -c conda-forge or use that in both cases:

    conda install --file requirements.txt



Now you can submit the job:

    qsub pipeline.pbs

### For alignments

Install muscle:

    # starting in app root
    mkdir -p src
    cd src

    wget https://drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
    tar -xzf muscle3.8.31_i86linux64.tar.gz
    mv muscle3.8.31_i86linux64 ../bin/

Install trimal:

    # starting in app root
    mkdir -p src
    cd src
    wget https://github.com/scapella/trimal/archive/v1.4.1.tar.gz
    tar -xzf v1.4.1.tar.gz
    cd trimal-1.4.1/source
    make
    cp trimal readal ../../../bin/
