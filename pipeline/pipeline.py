# module to hold pipeline functions and classes
import re
import os
import enum
from Bio import SeqIO


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
    def __init__(self, feature, record, accession):
        self.feature = feature
        self.record = record
        self.accession = accession

    def length(self):
        return self.feature.location.end.position - self.feature.location.start.position

    def name(self):
        #FIXME: the four replaces at the end to match original pipeline from carstens; this can be simplified with better python
        return ((self.feature.qualifiers.get('gene') or self.feature.qualifiers.get('product'))[0] or '').replace(' ','-').replace('/','-').replace("'",'').replace(".",'')

    def abbreviation(self):
        #TODO: the abbreviation problem is unsolved; at this point we are just looking at a big lookup table
        # for starters we could add in the abbreviations that were recommended
        return self.name()

    def sequence():
        self.record.seq[self.feature.location.start.position:feature.location.end.position]

    def write_sequence(self, out_file):
        #FIXME: verify this doesn't trunctate a character you need:
        #FIXME: a more appropriate way? has the record already loaded the entire sequence into memory? if not perhaps we want to do this a different way?
        out_file.write(self.record.seq[self.feature.location.start.position:feature.location.end.position])

    def write_fasta(self, out_file):
        out_file.write(f'>{accession}\n')
        write_sequence(out_file)
        out_file.write('\n')

def genes_for_record(record, accession):
    return [Gene(f, record, accession) for f in record.features if (f.type == 'CDS' and ('gene' in f.qualifiers or 'product' in f.qualifiers)) ]


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

    def alt_species(self, occurrence, record):
        alt = ''
        organism = record.annotations.get('organism')

        if(organism and organism not in (
              occurrence[OccurrenceRecordIndex.SPECIES],
              ' '.join([occurrence[OccurrenceRecordIndex.SPECIES], occurrence[OccurrenceRecordIndex.SUBSPECIES]])
        )):
            alt = organism

        return alt

    def write_occurrence_record(self, gbif_out_file, occurrence, record):
        """append to end of occurrence source genbank filename and alt organism string"""
        gbif_out_file.write("\t".join(occurrence
         + [os.path.basename(self.genbank_path)]
         + [self.alt_species(occurrence, record)])
        )

    def write_gene_sequence_data(self):
        # create directory to store sequence data
        # for each gene, use lookup to get gene short name for gene
        # then create directory and write gene and sequences as files
        pass

    def write_gene_metadata_record(self, gene, out_file):
        out_file.write("\t".join([gene.accession, gene.name(), gene.abbreviation(), gene.sequence()]))

    def filter_gbif_occurrences_on_accession(self, gbif_file, db, gbif_out_file, postprocess = None):
        accessions_postprocessed = set()

        for line in gbif_file:
            # refactor to each_accession after move to class
            occurrence = line.split("\t")
            accession = occurrence[OccurrenceRecordIndex.ACCESSION]
            record = db.get(accession)
            if record:
                self.write_occurrence_record(gbif_out_file, occurrence, record)

                # post process only once per accession
                if postprocess and not accession in accessions_postprocessed:
                    postprocess(record, accession)
                    accessions_postprocessed.add(accession)

    def write_gene_data(self, record, accession):
        genes = genes_for_record(record, accession)
        gene_lengths = [g.length() for g in genes]

        max_gene_length = 0
        if(gene_lengths):
            max_gene_length = max(gene_lengths)

        with open(self.output_genes_path, 'w') as out_file:
            for gene in genes:
                self.write_gene_metadata_record(gene, out_file)

        print(f'{accession} has {len(genes)} genes and max gene length {max_gene_length}')

    def pipeline(self):
        db = self.make_index()

        # max_gene_length = 0
        with open(self.gbif_path, 'r') as gbif_file, open(self.output_occurrences_path, 'w') as gbif_out_file:
            self.filter_gbif_occurrences_on_accession(gbif_file, db, gbif_out_file, self.write_gene_data)

        # print(f'max_gene_length: {max_gene_length}')
