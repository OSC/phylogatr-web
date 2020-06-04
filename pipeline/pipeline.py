# module to hold pipeline functions and classes
import re
import os
import enum
from Bio import SeqIO


# FIXME: changing occurrence to an object would make the code easier to read
class OccurrenceRecordIndex(enum.IntEnum):
    """column names for gbif occurrences expanded on accession"""
    ACCESSION = 0
    GBIF_ID = enum.auto()
    LATITUDE = enum.auto()
    LONGITUDE = enum.auto()
    KINGDOM = enum.auto()
    PHYLUM = enum.auto()
    CLASS = enum.auto()
    ORDER = enum.auto()
    FAMILY = enum.auto()
    GENUS = enum.auto()
    SPECIES = enum.auto()
    SUBSPECIES = enum.auto()
    BASIS_OF_RECORD = enum.auto()
    GEODETIC_DATUM = enum.auto()
    ISSUE  = enum.auto()

def occurrence_without_null(occurrence):
    return ['' if x.strip() == '\\N' else x for x in occurrence]

def expand_gbif_occurrences_on_accession(gbif_file, gbif_out_file):
    accession_regex = re.compile('\w{2}\d{6}')
    for line in gbif_file:
        parts = occurrence_without_null(line.split("\t"))

        # omit occurrences that are missing KINGDOM through SPECIES
        if('' not in parts[OccurrenceRecordIndex.KINGDOM:OccurrenceRecordIndex.SUBSPECIES]):
            # expand the accession column
            for accession in accession_regex.findall(parts[0]):
                gbif_out_file.write("\t".join([accession] + parts[1:]))


class Gene:
    def __init__(self, feature, record, occurrence):
        self.feature = feature
        self.record = record
        self.occurrence = occurrence

    def accession(self):
        return self.occurrence[OccurrenceRecordIndex.ACCESSION]

    def fasta_file_prefix(self):
        return (self.occurrence[OccurrenceRecordIndex.SPECIES] + '-' + self.symbol()).replace(' ', '-') if self.symbol() else ''

    def start_position(self):
        return self.feature.location.start.position

    def end_position(self):
        return self.feature.location.end.position

    def species(self):
        return self.record.annotations.get('organism')

    def species_different_from_occurrence(self):
        return self.species() if self.species() != self.occurrence[OccurrenceRecordIndex.SPECIES] else ''

    def length(self):
        return self.end_position() - self.start_position()

    def name(self):
        #FIXME: the four replaces at the end to match original pipeline from carstens; this can be simplified with better python
        return ((self.feature.qualifiers.get('product') or [''])[0]).replace(' ','-').replace('/','-').replace("'",'').replace(".",'')

    def symbol(self):
        return ((self.feature.qualifiers.get('gene') or [''])[0] or '').replace(' ','-').replace('/','-').replace("'",'').replace(".",'').upper()

    def sequence(self):
        return str(self.record.seq[self.start_position():self.end_position()])

    def write_sequence(self, out_file):
        #FIXME: verify this doesn't trunctate a character you need:
        #FIXME: a more appropriate way? has the record already loaded the entire sequence into memory? if not perhaps we want to do this a different way?
        out_file.write(self.sequence())

    def write_fasta(self, out_file):
        out_file.write(f'>{accession}\n')
        write_sequence(out_file)
        out_file.write('\n')

def genes_for_record(record, occurrence):
    return [Gene(f, record, occurrence) for f in record.features if (f.type == 'CDS' and ('gene' in f.qualifiers or 'product' in f.qualifiers)) ]


def accession_from_version(version):
    return version.split('.')[0]


class Pipeline:
    def __init__(self, gbif_path, genbank_path, output_dir):
        self.gbif_path = gbif_path
        self.genbank_path = genbank_path
        self.output_dir = output_dir

        self.output_occurrences_path = os.path.join(self.output_dir, os.path.basename(self.genbank_path) + ".gbif.tsv");
        self.output_genes_path = os.path.join(self.output_dir, os.path.basename(self.genbank_path) + ".genes.tsv");

    def index_path(self):
        return os.path.join(self.output_dir, os.path.basename(self.genbank_path) + ".idx");

    def make_index(self):
        """Create if doesn't exist, then return BioPython flatfile index"""
        return SeqIO.index_db(self.index_path(), self.genbank_path, 'genbank', None, accession_from_version)

    def genbank_filename(self):
        return os.path.basename(self.genbank_path)

    def write_gene_metadata_record(self, gene, out_file):
        # TODO: source = os.path.basename(self.genbank_path)
        # TODO: gene.length() and gene.abbreviation()
        out_file.write("\t".join([gene.accession(), gene.symbol(), gene.name(), gene.fasta_file_prefix(), gene.species(), self.genbank_filename(), gene.sequence().lower()])+ "\n")

    def write_genes_for_sequences_in_occurrences(self, gbif_file, db, out_genes_file):
        """write all the gene info to a file once for each accession in gbif_file"""
        accessions_processed = set()
        for line in gbif_file:
            occurrence = line.split("\t")
            accession = occurrence[OccurrenceRecordIndex.ACCESSION]
            if not accession in accessions_processed:
                record = db.get(accession)
                if record:
                    genes = genes_for_record(record, occurrence)
                    for gene in genes:
                        self.write_gene_metadata_record(gene, out_genes_file)
                    accessions_processed.add(accession)

    def write_genes(self):
        db = self.make_index()
        with open(self.gbif_path, 'r') as gbif_file, open(self.output_genes_path, 'w') as out_genes_file:
            self.write_genes_for_sequences_in_occurrences(gbif_file, db, out_genes_file)
        db.close()
