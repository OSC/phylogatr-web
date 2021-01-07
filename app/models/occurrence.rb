class Occurrence < ActiveRecord::Base
  acts_as_mappable

  def self.update_all_species_metrics
    where(species_total_bytes: nil).distinct.pluck(:species_path).each {|p| Species.update_occurrences p }
  end

  def species
    Species.new(Configuration.genbank_root.join(species_path))
  end

  def self.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
    if swpoint.all?(&:present?) && nepoint.all?(&:present?) && taxonomy.present?
      Occurrence.in_bounds([swpoint, nepoint]).where(taxonomy).order(:taxon_species, :accession)
    elsif swpoint.all?(&:present?) && nepoint.all?(&:present?)
      Occurrence.in_bounds([swpoint, nepoint]).order(:taxon_species, :accession)
    elsif taxonomy.present?
      Occurrence.where(taxonomy).order(:taxon_species, :accession)
    else
      Occurrence.all
    end
  end

  def latitude
    read_attribute_before_type_cast(:lat)
  end
  def longitude
    read_attribute_before_type_cast(:lng)
  end

  def self.headers
    %w(
      accession
      gbif_id
      latitude
      longitude
      basis_of_record
      geodetic_datum
      coordinate_uncertainty_in_meters
      issue
    )
  end

  def self.headers_tsv
    headers.join("\t") + "\n"
  end

  def to_str
    @str ||= self.class.headers.map {|a| self.send(a) }.join("\t")+"\n"
  end
end
