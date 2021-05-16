require 'test_helper'

class OccurrenceRecordTest < ActiveSupport::TestCase
  test "invalid if any clade names have an integer in the name" do
    refute OccurrenceRecord.new(taxon_species: "bad1 species").valid?
  end

  test "invalid if basis of record invalid" do
    refute OccurrenceRecord.new.valid?
    refute OccurrenceRecord.new(basis_of_record: "LIVING_SPECIMEN", lat: 35.766701, lon: -74.849999).valid?
  end

  test "valid if basis of record valid" do
     assert OccurrenceRecord.new(basis_of_record: "PRESERVED_SPECIMEN", lat: 35.766701, lon: -74.849999, taxon_class: 'Reptilia').valid?
  end

  test "not duplicate if locations differ" do
    o1 = OccurrenceRecord.new(lat: 35.766701, lon: -74.859999, taxon_class: 'Reptilia', basis_of_record: 'PRESERVED_SPECIMEN')
    o2 = OccurrenceRecord.new(lat: 30.76, lon: -74.849999, taxon_class: 'Reptilia', basis_of_record: 'PRESERVED_SPECIMEN')

    records = OccurrenceRecord.filter([o1, o2])
    assert_equal 2, records.count
    assert_equal 'g', records.first.flag
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

  test ".each_occurrence_slice_grouped_by_accession" do
    io = StringIO.new <<~EOF
    KY172636	2306662591	7.88	34.43	Animalia	Chordata	Actinopterygii	Osteoglossiformes	Mormyridae	Marcusenius	Marcusenius cyprinoides		MATERIAL_SAMPLE			GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES
    KY172637	2304695724	7.88	34.43	Animalia	Chordata	Actinopterygii	Osteoglossiformes	Mormyridae	Marcusenius	Marcusenius cyprinoides		MATERIAL_SAMPLE			GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES
    KY172637	2304695724	7.88	34.43	Animalia	Chordata	Actinopterygii	Osteoglossiformes	Mormyridae	Marcusenius	Marcusenius cyprinoides		MATERIAL_SAMPLE			GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES
    KY172638	2304695724	7.88	34.43	Animalia	Chordata	Actinopterygii	Osteoglossiformes	Mormyridae	Marcusenius	Marcusenius cyprinoides		MATERIAL_SAMPLE			GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES
    KY172638	2304695724	7.88	34.43	Animalia	Chordata	Actinopterygii	Osteoglossiformes	Mormyridae	Marcusenius	Marcusenius cyprinoides		MATERIAL_SAMPLE			GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES

    EOF

    slices = OccurrenceRecord.each_occurrence_slice_grouped_by_accession(io).to_a
    assert 3, slices.count
    assert_equal %w(KY172636), slices[0].map(&:accession)
    assert_equal %w(KY172637 KY172637), slices[1].map(&:accession)
    assert_equal %w(KY172638 KY172638), slices[2].map(&:accession)
  end

  test ".filter" do
    # FIXME: hard to test
    str = "KY172636	2306662591	7.88	34.43	Animalia	Chordata	Actinopterygii	Osteoglossiformes	Mormyridae	Marcusenius	Marcusenius cyprinoides			MATERIAL_SAMPLE	GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES			KY172636	2014-04-07T00:00:00"
    result = OccurrenceRecord.filter([OccurrenceRecord.from_str(str), OccurrenceRecord.from_str(str.sub('2306662591', '2306662592')), OccurrenceRecord.from_str(str.sub('2306662591', '2306662593'))])
    assert_equal 1, result.count
    assert_equal "KY172636", result.first.accession
    assert_equal "2306662593", result.first.gbif_id
  end

  test "#from_str" do
    str = "KY172636	2306662591	7.88	34.43	Animalia	Chordata	Actinopterygii	Osteoglossiformes	Mormyridae	Marcusenius	Marcusenius cyprinoides			MATERIAL_SAMPLE	GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES			KY172636	2014-04-07T00:00:00"
    o = OccurrenceRecord.from_str(str)
    assert_equal "KY172636", o.accession
    assert_equal "2306662591", o.gbif_id
    assert_equal "Animalia", o.taxon_kingdom
    assert_equal "Marcusenius cyprinoides", o.taxon_species
    assert_equal "MATERIAL_SAMPLE", o.basis_of_record
    assert_equal "MATERIAL_SAMPLE", o.basis_of_record
    assert_equal "GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES", o.issue

  end

  test "#to_str" do
    str = "KY172636	2306662591	7.88	34.43	Animalia	Chordata	Actinopterygii	Osteoglossiformes	Mormyridae	Marcusenius	Marcusenius cyprinoides			MATERIAL_SAMPLE	GEODETIC_DATUM_ASSUMED_WGS84COUNTRY_DERIVED_FROM_COORDINATES			KY172636	2014-04-07T00:00:00"
    record = OccurrenceRecord.from_str(str)
    assert_equal str + "\t", record.to_str
    record.flag = 'g'
    assert_equal str + "\tg", record.to_str
  end
end
