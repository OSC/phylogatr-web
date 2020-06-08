class Occurrence < ActiveRecord::Base
  acts_as_mappable

  def species
    Species.new(Configuration.genbank_root.join(species_path))
  end

  def self.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
    #TODO: what to add to occurrences table so we can avoid this join?
    Occurrence
        .in_bounds([swpoint, nepoint]).where(taxonomy)
        .order(:taxon_species, :accession)
  end

  def self.headers
    %w(
      accession
      gbif_id
      latitude
      longitude
      taxon_kingdom
      taxon_phylum
      taxon_class
      taxon_order
      taxon_family
      taxon_genus
      taxon_species
      taxon_subspecies
      different_genbank_species
      basis_of_record
      geodetic_datum
      coordinate_uncertainty_in_meters
      issue
    )
  end

  def latitude
    read_attribute_before_type_cast(:lat)
  end
  def longitude
    read_attribute_before_type_cast(:lng)
  end

  def self.headers_tsv
    headers.join("\t") + "\n"
  end

  def to_str
    @str ||= self.class.headers.map {|a| self.send(a) }.join("\t")+"\n"
  end
end
