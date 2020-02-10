# module to hold pipeline functions and classes
import re
import os
from Bio import SeqIO


class Sequence:
    pass


class Gene:
    pass

def accession_from_version(version):
    return version.split('.')[0]

class Pipeline:
    def __init__(self, gbif_path, genbank_path, index_path):
        self.gbif_path = gbif_path
        self.genbank_path = genbank_path

        # TODO: replace without output_dir_path, then join
        self.index_path = index_path

    def make_index(self):
        """Create if doesn't exist, then return BioPython flatfile index"""
        return SeqIO.index_db(self.index_path, self.genbank_path, 'genbank', None, accession_from_version)

    def write_expanded_occurrence_record(self, accession, parts, record):
        # add columns:
        # 1. alt organism if genbank organism differs from gbif
        # 2. genbank file source (basename self.genbank_path)
        # [accession] + clean(parts)[1:-1] + [alt organism] + [genbank]
        pass

    def write_gene_sequence_data(self):
        # create directory to store sequence data
        # for each gene, use lookup to get gene short name for gene
        # then create directory and write gene and sequences as files
        pass

    def write_gene_metatada_record(self):
        # write gene metadata record to file:   genes.txt.part.X
        pass

    def pipeline(self):
        db = make_index(self.genbank_path, self.index_path)

        # maintain a set of accessions HERE
        sequences_written = set()

        accession_regex = re.compile('\w{2}\d{6}')

        with open(self.gbif_path) as gbif:
            for line in gbif:
                # refactor to each_accession after move to class
                parts = line.split("\t")
                for accession in accession_regex.findall(parts[0]):
                    record = db.get(accession)
                    if record:
                        write_expanded_occurrence_record(accession, parts, record)

                        if not accession in sequences_written:
                            self.write_gene_sequence_data()
                            self.write_gene_metatada_record()

                            sequences_written.add(accession)
