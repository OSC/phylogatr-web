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
