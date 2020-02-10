from invoke import task

import pipeline

@task
def make_index(c, genbank_path, index_path):
    pipeline.make_index(genbank_path, index_path)

@task
def run_pipeline(c, gbif_path, genbank_path, output_dir):
    pipeline.Pipeline(gbif_path, genbank_path, output_dir).pipeline()
