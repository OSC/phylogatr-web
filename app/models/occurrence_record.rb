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

  def to_str
    HEADERS.map { |h| self.send(h) }.join("\t")
  end

  def self.filter(occurrences)
    occurrences.reduce([]) do |keep, o|
      if o.valid?
        # if keep empty, keep it
        if keep.empty?
          keep << o
        else
          idx = keep.find_index { |i| o.duplicate?(i) }
          if(idx)
            # duplicate - use more recent
            keep[idx] = o if o.gbif_id > keep[idx].gbif_id
          else
            # not duplicate, append
            keep << o
          end
        end
      end

      # FIXME: at the end we need an array of Occurrences to keep and the REASON
      # and we need to add the REASON as a column to the database

      keep
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

