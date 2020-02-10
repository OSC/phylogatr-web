# module to hold pipeline functions and classes
import re
import os
from Bio import SeqIO


class Gene:
    def __init__(self, feature, record, accession):
        self.feature = feature
        self.record = record
        self.accession = accession

    def length(self):
        return self.feature.location.end.position - self.feature.location.start.position

    def name(self):
        return (self.feature.qualifiers.get('gene') or self.feature.qualifiers.get('product'))[0]

    def write_sequence(self, output_dir):
        # mkdir_p
        # write sequence header then body
        pass


def genes_for_record(record, accession):
    return [Gene(f, record, accession) for f in record.features if (f.type == 'CDS' and ('gene' in f.qualifiers or 'product' in f.qualifiers)) ]

def accession_from_version(version):
    return version.split('.')[0]

class Pipeline:
    def __init__(self, gbif_path, genbank_path, output_dir):
        self.gbif_path = gbif_path
        self.genbank_path = genbank_path
        self.output_dir = output_dir

    def expanded_occurrence_part_path(self):
        return os.path.join(self.output_dir, os.path.basename(self.genbank_path) + ".gbif");

    def index_path(self):
        return os.path.join(self.output_dir, os.path.basename(self.genbank_path) + ".idx");

    def make_index(self):
        """Create if doesn't exist, then return BioPython flatfile index"""
        return SeqIO.index_db(self.index_path(), self.genbank_path, 'genbank', None, accession_from_version)

    def write_expanded_occurrence_record(self, gbif_out_file, accession, parts, record):
        # add columns:
        # 1. alt organism if genbank organism differs from gbif
        # 2. genbank file source (basename self.genbank_path)
        # [accession] + clean(parts)[1:-1] + [alt organism] + [genbank]
        gbif_out_file.write("\t".join([accession] + parts[1:]))

    def write_gene_sequence_data(self):
        # create directory to store sequence data
        # for each gene, use lookup to get gene short name for gene
        # then create directory and write gene and sequences as files
        pass

    def write_gene_metatada_record(self):
        # write gene metadata record to file:   genes.txt.part.X
        pass

    def expand_gbif_occurrences_on_accession(self, gbif_file, db, gbif_out_file, postprocess = None):
        accessions_postprocessed = set()
        accession_regex = re.compile('\w{2}\d{6}')

        for line in gbif_file:
            # refactor to each_accession after move to class
            parts = line.split("\t")
            for accession in accession_regex.findall(parts[0]):
                record = db.get(accession)
                if record:
                    self.write_expanded_occurrence_record(gbif_out_file, accession, parts, record)

                    if postprocess and not accession in accessions_postprocessed:
                        postprocess(accession)
                        accessions_postprocessed.add(record, accession)

    def write_gene_data(self, record, accession):
        genes = genes_for_record(record, accession)
        gene_lengths = [g.length() for g in genes]

        # TODO: for each gene, write sequence data and write gene metadata

        return max(gene_lengths)

    def pipeline(self):
        db = self.make_index()

        # max_gene_length = 0
        with open(self.gbif_path, 'r') as gbif_file, open(self.expanded_occurrence_part_path(), 'w') as gbif_out_file:
            self.expand_gbif_occurrences_on_accession(gbif_file, db, gbif_out_file, lambda r, a: self.write_gene_data(r,a))

        # print(f'max_gene_length: {max_gene_length}')