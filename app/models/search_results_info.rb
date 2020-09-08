class SearchResultsInfo
  include ActiveModel::Serializers::JSON

  attr_accessor :num_species, :estimated_tar_size, :percent_complete, :message

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    instance_values
  end

  def save(path)
    Pathname.new(path).write(to_json)
  end

  def self.load(path)
    info = self.new
    info.from_json(Pathname.new(path).read)
  end

  def self.build(swpoint, nepoint, taxonomy)
    info = self.new
    info.num_species = self.num_species(swpoint, nepoint, taxonomy)
    info.estimated_tar_size = self.estimated_tar_size(swpoint, nepoint, taxonomy)
    info
  end

  def self.num_species(swpoint, nepoint, taxonomy)
    # FIXME: species table
    # FIXME: taxon_species is preferred to use once fixing pipeline issue
    Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy).distinct.count(:species_path)
  end

  def self.estimated_tar_size(swpoint, nepoint, taxonomy)
    Occurrence.from(
      Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
       .where.not(species_total_bytes: nil)
       .distinct
       .select(:species_path, :species_total_bytes)
    ).sum('subquery.species_total_bytes')
  end

  # TODO:
  # def seqs_per_species
  #   # FIXME: species table
  #   Occurrence.in_bounds_with_taxonomy(swpoint, nepoint, taxonomy)
  #     .select(:species_path, :species_total_seqs).distinct.as_json
  # end
end
