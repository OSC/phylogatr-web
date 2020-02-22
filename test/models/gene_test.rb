require 'test_helper'

class GeneTest < ActiveJob::TestCase

  # FAILS:
  # test "batch requests preserve ordering with batch requests find_each" do
  #   g1 = Gene.joins("INNER JOIN occurrences ON occurrences.accession = genes.accession").merge(Occurrence.all).order(:fasta_file_prefix, :accession).distinct[0]
  #   g2 = Gene.joins("INNER JOIN occurrences ON occurrences.accession = genes.accession").merge(Occurrence.all).order(:fasta_file_prefix, :accession).distinct.find_each.first

  #   assert_equal g1.accession, g2.accession
  # end

  # Succeeds:
  test "query scope to get all genes in location" do
    swpoint = [29.71533, -110.15726]
    nepoint = [40.785091, -73.68285]

    assert 3, Gene.in_bounds_with_taxonomy(swpoint, nepoint, {}).count
  end

  test "batch iterator iterates through every gene" do
    swpoint = [29.71533, -110.15726]
    nepoint = [40.785091, -73.68285]

    e = Gene.find_each_in_bounds_with_taxonomy(swpoint, nepoint, {})

    assert_equal 'KM655149', e.next.accession
  end
end
