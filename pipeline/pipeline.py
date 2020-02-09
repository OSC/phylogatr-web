# module to hold pipeline functions and classes
# TODO: reorganize as a standard python module

class Sequence:
    pass

class Gene:
    pass

def expand_accessions(occurrences_tsv_file, out_file):
    pass

def make_index(genbank_path, index_path):
    """Create if doesn't exist, then return BioPython flatfile index"""
    pass

#FIXME: better name?
# expects tsv file with first column the accession
def join_on_accessions(expanded_occurrences_tsv_file, genbank_path, index_path, out_file)
    """Create joined occurrences file and return set of accessions"""
    pass
