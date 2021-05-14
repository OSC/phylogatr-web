require 'test_helper'

class OccurrenceTest < ActiveSupport::TestCase
  test "source_id is a string" do
    assert_equal 'CFWIB234-10', Occurrence.new(source_id: 'CFWIB234-10').source_id
  end
end
