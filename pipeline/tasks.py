from invoke import task
from pathlib import Path

import pipeline

@task
def make_index(c, genbank_path, output_dir):
    p = pipeline.Pipeline('', genbank_path, output_dir)
    p.make_index()
    print(p.index_path())

@task
def write_genes(c, gbif_path, genbank_path, output_dir):
    pipeline.Pipeline(gbif_path, genbank_path, output_dir).write_genes()

@task
def expand_occurrences(c, gbif_path, output_path):
    with open(gbif_path, 'r') as gbif_file, open(output_path, 'w') as output_file:
        pipeline.expand_gbif_occurrences_on_accession(gbif_file, output_file)

@task
def trim_genes_and_occurrences_by_fasta_paths(c, genes_path, occurrences_path, fasta_paths_path):
    paths = set(Path(fasta_paths_path).read_text().split('\n'))
    accessions = set()

    out_genes_path = genes_path + ".trimmed"
    out_occurrences_path = occurrences_path + ".trimmed"

    # genes
    with open(genes_path, 'r') as genes_file, open(out_genes_path, 'w') as out:
        # if gene field 1 has path in set, write it to out
        # save accession of valid gene to set
        for line in genes_file:
            parts = line.strip().split("\t")
            if len(parts) > 0 and parts[0] in paths:
                accessions.add(parts[1])
                out.write(line)
   
    # occurrences
    with open(occurrences_path, 'r') as occurrences_file, open(out_occurrences_path, 'w') as out:
        # if occurrence field 1 in accession set, write it out
        for line in occurrences_file:
            parts = line.strip().split("\t")
            if len(parts) > 0 and parts[0] in accessions:
                out.write(line)

