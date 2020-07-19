# simple object representing record in original occurrence files
class OccurrenceRecord
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :accession, :gbif_id, :lat, :lon
  attr_accessor :taxon_kingdom, :taxon_phylum, :taxon_class, :taxon_order, :taxon_family, :taxon_genus, :taxon_species, :taxon_subspecies
  attr_accessor :basis_of_record, :geodetic_datum, :coordinate_uncertainty_in_meters, :issue
  attr_accessor :event_date

  validates_inclusion_of :basis_of_record, in: %w(PRESERVED_SPECIMEN MATERIAL_SAMPLE HUMAN_OBSERVATION MACHINE_OBSERVATION)
  validates_format_of :taxon_kingdom, :taxon_phylum, :taxon_class, :taxon_order, :taxon_family, :taxon_genus, :taxon_species, :taxon_subspecies, without: /\d/

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

  def more_recent(other)
    # or updated at?
    if gbif_id > other.gbif_id
      self
    else
      other
    end
  end

  def lat_rounded
    lat.round(2)
  end

  def lon_rounded
    lon.round(2)
  end
end
