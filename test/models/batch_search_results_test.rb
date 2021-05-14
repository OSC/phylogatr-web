require 'test_helper'

class BatchSearchResultsTest < ActiveJob::TestCase
  test "serialization and deserialization works" do
    params = { :taxon_class => 'Reptilia'}
    assert_equal params, BatchSearchResults.deserialize_params(BatchSearchResults.new(params).serialize_params)
  end

  test "serialization doesn't add newlines" do
    params = {
      :southwest_corner_latitude => 1.111,
      :southwest_corner_longitude => 1.111,
      :northeast_corner_latitude => 1.111,
      :northeast_corner_longitude =>1.111,
      :results_format => 'tar',
      :taxon_class => 'Reptilia'
    }
    refute BatchSearchResults.new(params).serialize_params.include?("\n")
  end
end
