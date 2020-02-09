from invoke import task

import pipeline

@task
def make_index(c, genbank_path, index_path):
    pipeline.make_index(genbank_path, index_path)

@task
def hellop(c):
    pipeline.hello()
