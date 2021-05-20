require 'test_helper'

class GbifGenbankLinkerTest < ActiveJob::TestCase
  include Enumerable

  # gbif_genbank_linker_test.genbank.txt and gbif_genbank_linker_test.gbif.txt in the same directory as this file
  def setup
    @gbif =  Pathname.new(__FILE__).dirname.join('gbif_genbank_linker_test.gbif.txt')
    @genbank = Pathname.new(__FILE__).dirname.join('gbif_genbank_linker_test.genbank.txt')

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

    # tests that rely on the actual downloads will be skipped unless these are
    # manually supplied
    # TODO: add how we get this
    @gbif_all = Rails.root.join('test/data/pipeline/input/0147211-200613084148143.filtered.txt.expanded')
  end

  test "can iterate over test occurrences data" do
    @gbif.open do |f|
      assert_equal @gbif_accessions, OccurrenceRecord.each_occurrence_slice_grouped_by_accession(f).to_a.flatten.map(&:accession)
    end
  end

  test "can iterate over genbank data" do
    @genbank.open do |f|
      accessions = []
      ff = Bio::GenBank.open(f)
      ff.each_entry do |entry|
        accessions << entry.accession
      end

      assert_equal  @genbank_accessions, accessions
    end
  end

  test "iterator links gbif records with genbank records" do
    @gbif.open do |gbif|
      @genbank.open do |genbank|
        assert_equal (@gbif_accessions & @genbank_accessions), GbifGenbankLinker.new(gbif, genbank).each.to_a.map(&:accession).sort
      end
    end
  end

  test "can step through iterator one at a time" do
    @gbif.open do |gbif|
      @genbank.open do |genbank|
        enum = GbifGenbankLinker.new(gbif, genbank).each
        assert_equal "AY099992", enum.next.accession
        seq = enum.next
        assert_equal "AY099996", seq.accession
        assert_equal ['543522280', '543522281'], seq.gbif_records.map(&:gbif_id)
      end
    end
  end

  test "can execute iterator multiple times and get the same result" do
    @gbif.open do |gbif|
      @genbank.open do |genbank|
        gb = GbifGenbankLinker.new(gbif, genbank)
        assert_equal gb.each.each.to_a.map(&:accession).sort, gb.each.each.to_a.map(&:accession).sort
      end
    end
  end

  test "seek closer to starting accession" do
    skip "need to add expanded gbif to #{@gbif_all}" unless @gbif_all.file?

    @gbif_all.open do |f|
      GbifGenbankLinker.seek_closer_to_starting_accession!(f, @genbank_accessions.first)

      # verify position has been moved
      assert f.pos > 0
    end
  end

  test "still works when seeking closer to start position" do
    skip "need to add expanded gbif to #{@gbif_all}" unless @gbif_all.file?

    @genbank.open do |genbank|
      @gbif_all.open do |gbif|
        gb = GbifGenbankLinker.new(gbif, genbank)
        assert_equal gb.each.each.to_a.map(&:accession).sort, gb.each.each.to_a.map(&:accession).sort
      end
    end
  end
end
