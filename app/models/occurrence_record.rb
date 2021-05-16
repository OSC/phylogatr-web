# TODO: merge with Occurrence model after switching to sqlite3
class OccurrenceRecord
  include ActiveModel::Model
  include ActiveModel::Validations

  HEADERS=[:accession, :gbif_id, :lat, :lon, :taxon_kingdom, :taxon_phylum, :taxon_class, :taxon_order, :taxon_family, :taxon_genus, :taxon_species, :taxon_subspecies, :coordinate_uncertainty_in_meters, :basis_of_record, :issue,  :field_number, :catalog_number, :identifier, :event_date]

  #FIXME: duplicate of OccurrencePostRecord but add tests first before refactoring
  #
  # headers after pipeline.py processes everything
  POST_HEADERS=[:species_path, *HEADERS, :flag, :different_genbank_species, :genes]

  HEADERS.each do |h|
    attr_accessor h
  end

  attr_accessor :flag

  # highest precendence last
  BASIS_OF_RECORD=%w(MACHINE_OBSERVATION HUMAN_OBSERVATION MATERIAL_SAMPLE PRESERVED_SPECIMEN)

  validates_each :lat, :lon do |record, attr, value|
    record.errors.add attr, "nil or 0" unless value.present? && OccurrenceRecord.float_rounded(value) != 0
  end

  validates_inclusion_of :basis_of_record, in: BASIS_OF_RECORD
  validates_format_of :taxon_kingdom, :taxon_phylum, :taxon_class, :taxon_order, :taxon_family, :taxon_genus, :taxon_species, :taxon_subspecies, without: /\d/

  def self.from_str(str)
    #FIXME: dangerous: should be using CSV reader/writer
    OccurrenceRecord.new(Hash[HEADERS.zip(str.chomp.split("\t", -1))])
  end

  # read the file line by line, processing
  def self.each_occurrence_slice_grouped_by_accession(tsv_file)
    return to_enum(:each_occurrence_slice_grouped_by_accession, tsv_file) unless block_given?

    tsv_file.each_line.lazy.map {|line|
      OccurrenceRecord.from_str(line)
    }.chunk_while {|i, j| i.accession == j.accession }.each { |chunk|
      yield chunk
    }
  end

  # output format includes flag
  def to_str
    (HEADERS.map { |h| self.send(h) } + [flag]).join("\t")
  end

  def self.same(records, attrs)
    records.uniq {|o|
      Array.wrap(attrs).map {|a| o.send(a) }
    }.count == 1
  end

  def self.flag(records, flag)
    records.each do |o|
      o.flag = flag
    end

    records
  end

  def self.records_with_highest_precendence_basis_of_record(records)
   # get the highest precendence basis of record
   index = records.map { |o| BASIS_OF_RECORD.index(o.basis_of_record) }.max
   # return all the records with that basis
   records.select { |o| o.basis_of_record == BASIS_OF_RECORD[index] }
  end

  def self.most_recent_record(records)
    records.max {|a, b| a.gbif_id.to_i <=> b.gbif_id.to_i }
  end

  def self.filter_by_species_and_event_date(records)
    if ! same(records, :taxon_species)
      flag([most_recent_record(records)], 's')
    elsif same(records, :event_date)
      flag([most_recent_record(records)], 'm')
    else
      flag(records, 'd')
    end
  end

  def self.filter(records)
    # ignore invalid records and duplicates of same gbif_id
    # duplicates of same gbif_id would be produced only by our
    # earlier expansion of a single record into multiple records, one
    # per accessions, if the accession appeared twice in the original record
    records = records.select(&:valid?).uniq {|r| r.gbif_id }

    # don't flag records if there are no duplicates
    return records unless records.count > 1

    # WARNING: this algorithm doesn't consider cases where:
    # 5 of 6 coords same, but 6th is different
    # 4 of 5 basis of record same, but 5th is different
    # etc.

    # 1. are geographic coordinates the same?
    if ! same(records, [:lng_rounded, :lng_rounded])
      # keep all records and flag with g
      flag(records, 'g')
    elsif ! same(records, :basis_of_record)
      # keep only highest precedence basis of record
      records = records_with_highest_precendence_basis_of_record(records)
      if(records.count > 1)
        filter_by_species_and_event_date(records)
      else
        flag(records, 'b')
      end
    else
      filter_by_species_and_event_date(records)
    end
  end

  # argument comparator (lambda) - otherwise compare first column
  # or just column comparison (0,1,2,3, etc.)
  def self.each_occurrence_slice_grouped_by_path(occurrences_tsv_file)
    return to_enum(:each_occurrence_slice_grouped_by_path, occurrences_tsv_file) unless block_given?

    occurrences = []

    occurrences_tsv_file.each_line do |line|
      #FIXME: CSV?
      o = line.chomp.split("\t")

      if occurrences.empty? || occurrences.first[0] == o[0]
        occurrences << o
      else
        yield occurrences

        occurrences = [o]
      end
    end

    yield occurrences unless occurrences.empty?
  end


  # TODO:
  # OccurrenceRecord.each_occurrence_slice_grouped_by_accession(STDIN) do |occurrences|
  #   OccurrenceRecord.filter(occurrences).each do |occurrence|
  #     puts occurrence.to_str
  #   end
  # end

  def duplicate?(other)
    if ! (lng_rounded == other.lng_rounded && lat_rounded == other.lat_rounded)
      false
    elsif taxon_species != other.taxon_species
      true
    elsif event_date != other.event_date
      false
    else
      true
    end
  end

  def self.float_rounded(value)
    value.to_f.round(2)
  end

  def lat_rounded
    self.class.float_rounded(lat)
  end

  def lng_rounded
    self.class.float_rounded(lon)
  end
end

