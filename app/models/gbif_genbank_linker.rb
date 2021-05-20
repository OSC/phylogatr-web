class GbifGenbankLinker

  class GenbankRecord
    attr_reader :record
    def initialize(record)
      @record = record
    end
  end

  class Sequence
    attr_reader :genbank_record
    attr_reader :gbif_records

    delegate :accession, to: :genbank_record

    # this also has occurrences and genes method that
    # handles duplicates and validations etc.

    def initialize(genbank_record, gbif_records)
      @genbank_record = genbank_record
      @gbif_records = gbif_records # OccurrenceRecord
    end
  end

  # gbif tsv io object ordered by accession
  # genbank flat file format ordered by accession
  def initialize(gbif, genbank)
    @gbif = gbif
    @genbank = genbank
  end

  # iterator works like this:
  # tab delimited io
  # GbifRecord GenbankRecord
  #
  #
  # each_valid_sequence(gbif_path, gb_path) do |sequence|
  #   sequence.genes.each do |gene|
  #     genes.write(gene.to_str)
  #   end
  #   sequence.occurrences.each do |occurrence|
  #     occurrences.write(occurrence.to_str)
  #   end
  # end
  #

  # this algorithm assumes
  #
  # 1. genbank flat file will have only 1 record per accession
  # 2. gbif tsv may have multiple records per accession
  #
  #
  # WARNING: this assumes genbank and gbif accessions are UPCASE
  def each
    return to_enum(:each) unless block_given?

    File.open(@gbif) do |gbifio|
      File.open(@genbank) do |genbankio|
        gbif_enum = OccurrenceRecord.each_occurrence_slice_grouped_by_accession(gbifio)
        records = gbif_enum.next

        ff = Bio::GenBank.open(genbankio)
        ff.each_with_index do |entry, index|
          until records.first&.accession >= entry.accession do
            records = gbif_enum.next
          end

          if records.first.accession == entry.accession
            yield Sequence.new(entry, records)
          end
        end
      rescue StopIteration => e
        # noop - end of the enumeration
      end
    end
  end
end
