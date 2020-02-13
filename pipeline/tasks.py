from invoke import task

import pipeline

@task
def make_index(c, genbank_path, output_dir):
    p = pipeline.Pipeline('', genbank_path, output_dir)
    p.make_index()
    print(p.index_path())

@task
def run_pipeline(c, gbif_path, genbank_path, output_dir):
    pipeline.Pipeline(gbif_path, genbank_path, output_dir).pipeline()

@task
def expand_occurrences(c, gbif_path, output_path):
    with open(gbif_path, 'r') as gbif_file, open(output_path, 'w') as output_file:
        pipeline.expand_gbif_occurrences_on_accession(gbif_file, output_file)
