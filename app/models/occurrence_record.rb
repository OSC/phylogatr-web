# TODO: merge with Occurrence model after switching to sqlite3
class OccurrenceRecord
  include ActiveModel::Model
  include ActiveModel::Validations

  HEADERS=[:accession, :gbif_id, :lat, :lon, :taxon_kingdom, :taxon_phylum, :taxon_class, :taxon_order, :taxon_family, :taxon_genus, :taxon_species, :taxon_subspecies, :basis_of_record, :geodetic_datum, :coordinate_uncertainty_in_meters, :issue]

  HEADERS.each do |h|
    attr_accessor h
  end

  attr_accessor :event_date

  validates_inclusion_of :basis_of_record, in: %w(PRESERVED_SPECIMEN MATERIAL_SAMPLE HUMAN_OBSERVATION MACHINE_OBSERVATION)
  validates_format_of :taxon_kingdom, :taxon_phylum, :taxon_class, :taxon_order, :taxon_family, :taxon_genus, :taxon_species, :taxon_subspecies, without: /\d/

  def self.from_str(str)
    #FIXME: dangerous: should be using CSV reader/writer
    OccurrenceRecord.new(Hash[HEADERS.zip(str.chomp.split("\t", -1))])
  end

  # read the file line by line, processing
  def self.each_occurrence_slice_grouped_by_accession(occurrences_tsv_file)
    return to_enum(:each_occurrence_slice_grouped_by_accession, occurrences_tsv_file) unless block_given?

    occurrences = []

    occurrences_tsv_file.each_line do |line|
      o = OccurrenceRecord.from_str(line)

      if occurrences.empty? || occurrences.first.accession == o.accession
        occurrences << o
      else
        yield occurrences

        occurrences = [o]
      end
    end

    yield occurrences unless occurrences.empty?
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

      keep
    end
  end

  # TODO:
  # OccurrenceRecord.each_occurrence_slice_grouped_by_accession(STDIN) do |occurrences|
  #   OccurrenceRecord.filter(occurrences).each do |occurrence|
  #     puts occurrence.to_str
  #   end
  # end

  def duplicate?(other)
    if ! (lon_rounded == other.lon_rounded && lat_rounded == other.lat_rounded)
      false
    elsif taxon_species != other.taxon_species
      true
    elsif event_date != other.event_date
      false
    else
      true
    end
  end

  def lat_rounded
    lat.to_f.round(2)
  end

  def lon_rounded
    lon.to_f.round(2)
  end
end
