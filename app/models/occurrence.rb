class Occurrence < ActiveRecord::Base
  acts_as_mappable

  def self.in_bounds_with_taxonomy_joins_genes(swpoint, nepoint, taxonomy)
    Occurrence.joins("INNER JOIN genes ON occurrences.accession = genes.accession")
        .in_bounds([swpoint, nepoint]).where(taxonomy)
        .merge(Gene.where.not(sequence_aligned: nil))
        .order(:taxon_species, :accession)
  end

  def self.find_each_in_bounds_with_taxonomy_joins_genes(swpoint, nepoint, taxonomy, batch_size: 1024)
    return to_enum(:find_each_in_bounds_with_taxonomy_joins_genes, swpoint, nepoint, taxonomy, batch_size: batch_size) unless block_given?

    #FIXME: below is problematic if the queries are happening while the database is
    # being modified
    count = self.in_bounds_with_taxonomy_joins_genes(swpoint, nepoint, taxonomy).count

    (0..count).step(batch_size) do |offset|
      self.in_bounds_with_taxonomy_joins_genes(swpoint, nepoint, taxonomy)
          .select('occurrences.*, genes.taxon_genbank_species')
          .limit(batch_size)
          .offset(offset).each do |occurrence|
        yield occurrence
      end
    end
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

  def different_genbank_species
    if attribute_present?(:taxon_genbank_species) && read_attribute(:taxon_genbank_species) != taxon_species
      read_attribute(:taxon_genbank_species)
    else
      ""
    end
  end

  def self.headers_tsv
    headers.join("\t") + "\n"
  end

  def to_str
    self.class.headers.map {|a| self.send(a) }.join("\t")+"\n"
  end
end
