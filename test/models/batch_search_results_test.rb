require 'test_helper'

class BatchSearchResultsTest < ActiveJob::TestCase
  test "serialization and deserialization works" do
    params = { :taxon_class => 'Reptilia'}
    assert_equal params, BatchSearchResults.deserialize_params(BatchSearchResults.new(params).serialize_params)
  end
end
