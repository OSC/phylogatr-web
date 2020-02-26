require 'test_helper'

class SearchResultsTest < ActiveJob::TestCase
  # FIXME: these tests failed to catch problems when using MySQL
  # test "summary includes correct fasta lengths" do
  #   fa1 = genes(:obsoletus1).to_fasta.length + genes(:obsoletus2).to_fasta.length
  #   fa2 = genes(:vulpinus).to_fasta.length

  #   swpoint = [29, -110]
  #   nepoint = [45, -73]

  #   summary = SearchResults.new(swpoint, nepoint, {}).summary

  #   assert_equal fa1, summary[0]["fa_length"]
  #   assert_equal fa2, summary[1]["fa_length"]
  # end

  # test "summary includes correct aligned fasta lengths" do
  #   fa1 = genes(:obsoletus1).to_aligned_fasta.length + genes(:obsoletus2).to_aligned_fasta.length
  #   fa2 = genes(:vulpinus).to_aligned_fasta.length

  #   swpoint = [29, -110]
  #   nepoint = [45, -73]

  #   summary = SearchResults.new(swpoint, nepoint, {}).summary

  #   assert_equal fa1, summary[0]["afa_length"]
  #   assert_equal fa2, summary[1]["afa_length"]
  # end
end
