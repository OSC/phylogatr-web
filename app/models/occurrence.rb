class Occurrence < ActiveRecord::Base
  belongs_to :species
  acts_as_mappable

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
