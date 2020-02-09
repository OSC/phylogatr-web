from invoke import task

import pipeline

@task
def make_index(c, genbank_path, index_path):
    print("Hello")

@task
def hellop(c):
    pipeline.hello()
