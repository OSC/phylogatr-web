# module to hold pipeline functions and classes
import re
import os
import enum
from Bio import SeqIO
from collections import OrderedDict
import pprint


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
    COORDINATE_UNCERTAINTIY_IN_METERS = enum.auto()
    ISSUE  = enum.auto()


# precedence is the value - larger is higher precendence
VALID_BASIS = {"PRESERVED_SPECIMEN":3, "MATERIAL_SAMPLE":2, "HUMAN_OBSERVATION":1, "MACHINE_OBSERVATION":0  }

class OccurrencesWriter:
    def __init__(self):
        self.occurrences = OrderedDict() 


    def add_with_gene(self, occurrence, different_species):
        path = os.path.join(occurrence[OccurrenceRecordIndex.CLASS],
               occurrence[OccurrenceRecordIndex.ORDER],
               occurrence[OccurrenceRecordIndex.FAMILY],
               occurrence[OccurrenceRecordIndex.SPECIES]).replace(' ', '-')

        self.occurrences[occurrence[OccurrenceRecordIndex.ACCESSION]] = (occurrence + [different_species, path])

    def add(self, occurrence):
        accession = occurrence[OccurrenceRecordIndex.ACCESSION]

        if accession in self.occurrences and self.greater_than(occurrence, self.occurrences[accession]):
            self.occurrences[accession] = occurrence + self.occurrences[accession][-2:]

    def write(self, out_file):
        for o in self.occurrences.values():
            # pprint.pprint(o)
            #FIXME: hack - a  newline is added to the end of occurrence, not sure where
            out_file.write("\t".join(o).replace('\n','') + "\n")

    # retur true if o1 > o2; false otherwise
    def greater_than(self, o1, o2):
        b1 = VALID_BASIS.get(o1[OccurrenceRecordIndex.BASIS_OF_RECORD]) or 0
        b2 = VALID_BASIS.get(o2[OccurrenceRecordIndex.BASIS_OF_RECORD]) or 0

        # TODO: add distance in meters, other metrics after refactoring to Occurrence class
        # and improving tests
        return b1 > b2
        # return False


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

    def fasta_file_path(self):
        return os.path.join(self.occurrence[OccurrenceRecordIndex.CLASS],
               self.occurrence[OccurrenceRecordIndex.ORDER],
               self.occurrence[OccurrenceRecordIndex.FAMILY],
               self.occurrence[OccurrenceRecordIndex.SPECIES],
               self.fasta_file_prefix()).replace(' ', '-') if self.symbol() else ''

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

def genes_with_symbols(genes):
    return [gene for gene in genes if gene.symbol()]


def accession_from_version(version):
    return version.split('.')[0]


class Pipeline:
    def __init__(self, gbif_path, genbank_path, output_dir):
        self.gbif_path = gbif_path
        self.genbank_path = genbank_path
        self.output_dir = output_dir

        self.output_genes_path = os.path.join(self.output_dir, os.path.basename(self.genbank_path) + ".genes.tsv");
        self.output_occurrences_path = os.path.join(self.output_dir, os.path.basename(self.genbank_path) + ".genes.tsv.occurrences");

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
        out_file.write("\t".join([gene.fasta_file_path(), gene.accession(), gene.symbol(), gene.name(), gene.fasta_file_prefix(), gene.species(), self.genbank_filename(), gene.sequence().lower()])+ "\n")

    def write_genes_for_sequences_in_occurrences(self, gbif_file, db, out_genes_file, out_occurrences_file):
        """write all the gene info to a file once for each accession in gbif_file"""

        # TODO: build occurrences up now throwing out duplicates for the same accession (so Occurrence, add())

        accessions_processed = set()
        occurrences = OccurrencesWriter()

        for line in gbif_file:
            occurrence = line.split("\t")

            #FIXME: Occurrence class to handle this
            accession = occurrence[OccurrenceRecordIndex.ACCESSION]
            valid_basis = occurrence[OccurrenceRecordIndex.BASIS_OF_RECORD] in VALID_BASIS
            valid_taxonomy = (not bool(re.search(r'\d', ''.join(occurrence[OccurrenceRecordIndex.KINGDOM:OccurrenceRecordIndex.SUBSPECIES]))))

            if((not accession in accessions_processed) and valid_basis and valid_taxonomy):
                record = db.get(accession)
                if record:
                    # FIXME: we will want to write out the genes without symbols to another file for debugging purposes in the future
                    genes = genes_with_symbols(genes_for_record(record, occurrence))
                    for gene in genes:
                        self.write_gene_metadata_record(gene, out_genes_file)
                    accessions_processed.add(accession)

                    if(len(genes) > 0):
                        occurrences.add_with_gene(occurrence, genes[0].species_different_from_occurrence())
            elif(valid_basis):
                occurrences.add(occurrence)

        occurrences.write(out_occurrences_file)

    def write_genes(self):
        db = self.make_index()
        with open(self.gbif_path, 'r') as gbif_file, open(self.output_genes_path, 'w') as out_genes_file, open(self.output_occurrences_path, 'w') as out_occurrences_file:
            self.write_genes_for_sequences_in_occurrences(gbif_file, db, out_genes_file, out_occurrences_file)
        db.close()
