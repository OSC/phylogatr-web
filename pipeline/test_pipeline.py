import unittest
import pipeline

class TestHello(unittest.TestCase):

    def test_hello(self):
        self.assertEqual('hi', pipeline.gethi()) 

if __name__ == '__main__':
    unittest.main()
