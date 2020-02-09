import unittest
import pipeline

class TestPipeline(unittest.TestCase):

    def test_accession_from_version(self):
        self.assertEqual('AA000001', pipeline.accession_from_version('AA000001'))
        self.assertEqual('AA000001', pipeline.accession_from_version('AA000001.1'))

if __name__ == '__main__':
    unittest.main()
