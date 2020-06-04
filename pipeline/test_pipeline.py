import unittest
from io import StringIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq
import pipeline
from pipeline import Pipeline
from pathlib import Path

class TestPipeline(unittest.TestCase):

    def test_accession_from_version(self):
        self.assertEqual('AA000001', pipeline.accession_from_version('AA000001'))
        self.assertEqual('AA000001', pipeline.accession_from_version('AA000001.1'))

    def test_index_path(self):
        self.assertEqual('gbvrt94.seq.idx', Pipeline('', 'gbvrt94.seq', '').index_path())
        self.assertEqual('/out/gbvrt94.seq.idx', Pipeline('', '/genbank/files/gbvrt94.seq', '/out').index_path())

    def test_expand_gbif_occurrences_on_accession(self):
        # TODO: add taxonomoy, and test for alternate organism, genbank source file, etc.
        tsv = "https://www.ncbi.nlm.nih.gov/nuccore/MG076766\t1841684417\t43.37\t-80.36\n" + \
              "https://www.ncbi.nlm.nih.gov/nuccore/KT604601| other\t1841684418\t54.76\t-126.93\n" + \
              "https://www.ncbi.nlm.nih.gov/nuccore/KT605555| other\t1841684419\t56.26\t-124.33\n"
        expected_tsv = "MG076766\t1841684417\t43.37\t-80.36\n" + \
              "KT604601\t1841684418\t54.76\t-126.93\n" + \
              "KT605555\t1841684419\t56.26\t-124.33\n"
        out = StringIO()

        pipeline.expand_gbif_occurrences_on_accession(StringIO(tsv), out)

        self.assertEqual(expected_tsv, out.getvalue())

        # Animalia        Arthropoda      Insecta Diptera Chironomidae    \N      \N      \N
        # good example of a bad use case => there is no species specified though we could fill in the gaps
        # with the accession; or for the accession, get the taxid, and use that to get the full blessed
        # taxonomy => which I think is preferable

    def test_occurrence_without_null(self):
        self.assertEqual(['one', '', '', 'four'], pipeline.occurrence_without_null(['one', '\\N',' \\N ', 'four']))

    def test_alt_species_same(self):
        record = SeqRecord('ATGC', annotations={'organism': 'Pantherophis vulpinus'})
        occurrence = ['' for x in range(1, len(pipeline.OccurrenceRecordIndex))]
        occurrence[pipeline.OccurrenceRecordIndex.SPECIES] = 'Pantherophis vulpinus'
        gene = pipeline.Gene(None, record, occurrence)

        self.assertEqual('Pantherophis vulpinus', gene.species())
        self.assertEqual('', gene.species_different_from_occurrence())

    def test_alt_species_different(self):
        record = SeqRecord('ATGC', annotations={'organism': 'Pantherophis v.'})
        occurrence = ['' for x in range(1, len(pipeline.OccurrenceRecordIndex))]
        occurrence[pipeline.OccurrenceRecordIndex.SPECIES] = 'Pantherophis vulpinus'

        gene = pipeline.Gene(None, record, occurrence)
        self.assertEqual('Pantherophis v.', gene.species())
        self.assertEqual('Pantherophis v.', gene.species_different_from_occurrence())

    def test_write_genes_for_sequences(self):
        out = StringIO()
        seq_path = 'test/fixtures/panthropis.seq'
        gbif_path = 'test/fixtures/panthropis.seq.idx.occurrences'
        with open(gbif_path, 'r') as gbif_file: 
            p = Pipeline(gbif_path, seq_path,'test/fixtures')
            db = p.make_index()
            p.write_genes_for_sequences_in_occurrences(gbif_file, db, out)

            self.maxDiff = None
            expected = Path('test/fixtures/expected_genes').read_text().split("\n")
            actual = out.getvalue().split("\n")

            # test first line
            self.assertEqual(expected[0], actual[0])
            self.assertEqual(len(expected), len(actual))
            for i in range(0, len(expected)):
                self.assertEqual(expected[i], actual[i])

            db.close()
            out.close()
        

if __name__ == '__main__':
    unittest.main()
