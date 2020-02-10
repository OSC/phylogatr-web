import unittest
import pipeline
from pipeline import Pipeline

class TestPipeline(unittest.TestCase):

    def test_accession_from_version(self):
        self.assertEqual('AA000001', pipeline.accession_from_version('AA000001'))
        self.assertEqual('AA000001', pipeline.accession_from_version('AA000001.1'))

    def test_index_path(self):
        self.assertEqual('gbvrt94.seq.idx', Pipeline('', 'gbvrt94.seq', '').index_path())
        self.assertEqual('/out/gbvrt94.seq.idx', Pipeline('', '/genbank/files/gbvrt94.seq', '/out').index_path())

if __name__ == '__main__':
    unittest.main()
