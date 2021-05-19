require 'test_helper'

class GbifGenbankLinkerTest < ActiveJob::TestCase
  include Enumerable

  # gbif_genbank_linker_test.genbank.txt and gbif_genbank_linker_test.gbif.txt in the same directory as this file
  def setup
    @gbif = File.join(File.dirname(__FILE__), 'gbif_genbank_linker_test.gbif.txt')
    @genbank = File.join(File.dirname(__FILE__), 'gbif_genbank_linker_test.genbank.txt')

    # the sample gbif test file above has these accessions:
    @gbif_accessions = %w(
      80720161
      AY099992
      AY099996
      AY099996
      AY100002
      AY100003
      AY308770
      AY308771
      AY308771
      AY308773
      AY308778
    )

    # the example genbank file has these:
    @genbank_accessions = %w(
      AY099992
      AY099996
      AY308768
      AY308769
      AY308770
      AY308771
      AY308772
      AY308773
    )

  end

  test "can iterate over test occurrences data" do
    assert_equal @gbif_accessions, OccurrenceRecord.each_occurrence_slice_grouped_by_accession(File.open(@gbif)).to_a.flatten.map(&:accession)
  end

  test "can iterate over genbank data" do
    accessions = []
    ff = Bio::GenBank.open(@genbank)
    ff.each_entry do |entry|
      accessions << entry.accession
    end
    ff.close

    assert_equal  @genbank_accessions, accessions
  end

  test "iterator links gbif records with genbank records" do
    gbif = File.open(@gbif)
    genbank = File.open(@genbank)

    assert_equal (@gbif_accessions & @genbank_accessions), GbifGenbankLinker.new(gbif, genbank).each.to_a.map(&:accession).sort

  ensure
    gbif.close
    genbank.close
  end

  test "can step through iterator one at a time" do
    gbif = File.open(@gbif)
    genbank = File.open(@genbank)

    enum = GbifGenbankLinker.new(gbif, genbank).each
    assert_equal "AY099992", enum.next.accession
    seq = enum.next
    assert_equal "AY099996", seq.accession
    assert_equal ['543522280', '543522281'], seq.gbif_records.map(&:gbif_id)
  ensure
    gbif.close
    genbank.close
  end
end