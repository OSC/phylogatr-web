require 'test_helper'

class OccurrenceRecordTest < ActiveSupport::TestCase
  test "invalid if any clade names have an integer in the name" do
    refute OccurrenceRecord.new(taxon_species: "bad1 species").valid?
  end

  test "invalid if basis of record invalid" do
    refute OccurrenceRecord.new.valid?
    refute OccurrenceRecord.new(basis_of_record: "LIVING_SPECIMEN").valid?
  end

  test "valid if basis of record valid" do
     assert OccurrenceRecord.new(basis_of_record: "PRESERVED_SPECIMEN").valid?
  end

  test "not duplicate if locations differ" do
    o1 = OccurrenceRecord.new(lat: 35.766701, lon: -74.849999)
    o2 = OccurrenceRecord.new(lat: 30.76, lon: -74.849999)

    refute  o1.duplicate?(o2)
  end

  test "duplicate if everything else same" do
    o1 = OccurrenceRecord.new(lat: 35.766701, lon: -74.849999)
    o2 = OccurrenceRecord.new(lat: 35.766701, lon: -74.849999)

    assert o1.duplicate?(o2)
  end

  test "duplicate lon and lat same but species differ" do
    o1 = OccurrenceRecord.new(gbif_id: 1, lat: 35.766701, lon: -74.849999, taxon_species: "Foo")
    o2 = OccurrenceRecord.new(gbif_id: 2, lat: 35.766701, lon: -74.849999, taxon_species: "Bar")

    assert o1.duplicate?(o2)
  end

  test "not a duplicate if event dates differ and everything else same" do
    o1 = OccurrenceRecord.new(lat: 35.766701, lon: -74.849999, event_date: "2005")
    o2 = OccurrenceRecord.new(lat: 35.766701, lon: -74.849999, event_date: "2006")

    refute o1.duplicate?(o2)
  end

  test "lat rounds to nearest 2nd digit" do
    o1 = OccurrenceRecord.new(lat: 35.766701, lon: -74.849999)
    o2 = OccurrenceRecord.new(lat: 35.77, lon: -74.849999)

    assert_equal 35.77, o1.lat_rounded
    assert o1.duplicate?(o2)
  end
end
