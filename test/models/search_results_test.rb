require 'test_helper'

class SearchResultsTest < ActiveJob::TestCase
  # test "reduce_taxonomy_to_one_constraint handles nil" do
  #   # does where({}) work?
  #   assert_equal({}, SearchResults.new(nil, nil, nil).reduce_taxonomy_to_one_constraint(nil))
  # end

  # test "reduce_taxonomy_to_one_constraint handles no taxon specified" do
  #   assert_equal({}, SearchResults.new(nil, nil, nil).reduce_taxonomy_to_one_constraint({taxon_kingdom: nil, taxon_class: nil}))
  # end

  # test "reduce_taxonomy_to_one_constraint handles empty taxon specified" do
  #   assert_equal({}, SearchResults.new(nil,nil,nil).reduce_taxonomy_to_one_constraint({taxon_kingdom: '', taxon_class: ''}))
  # end

  # test "reduce_taxonomy_to_one_constraint reduces one" do
  #   assert_equal({:taxon_class => 'Reptilia'}, SearchResults.new(nil,nil,nil).reduce_taxonomy_to_one_constraint({taxon_kingdom: nil, taxon_class: 'Reptilia'}))
  # end

  # test "reduce_taxonomy_to_one_constraint reduces multiple in the right precedence" do
  #   assert_equal({:taxon_class => 'Reptilia'}, SearchResults.new.reduce_taxonomy_to_one_constraint({taxon_kingdom: 'Animalia', taxon_class: 'Reptilia'}))
  # end


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
