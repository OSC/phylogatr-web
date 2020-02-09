# module to hold pipeline functions and classes
# TODO: reorganize as a standard python module

from Bio import SeqIO

class Sequence:
    pass

class Gene:
    pass

def expand_accessions(occurrences_tsv_file, out_file):
    pass

def accession_from_version(version):
    return version.split('.')[0]

def make_index(genbank_path, index_path):
    """Create if doesn't exist, then return BioPython flatfile index"""
    return SeqIO.index_db(index_path, genbank_path, 'genbank', None, accession_from_version)


#FIXME: better name?
# expects tsv file with first column the accession
def join_on_accessions(expanded_occurrences_tsv_file, genbank_path, index_path, out_file)
    """Create joined occurrences file and return set of accessions"""
    pass
