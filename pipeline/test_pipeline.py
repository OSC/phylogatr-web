import unittest
from io import StringIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq
import pipeline
from pipeline import Pipeline

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

if __name__ == '__main__':
    unittest.main()
