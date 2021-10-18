class Occurrence < ApplicationRecord
  belongs_to :species
  acts_as_mappable

  enum source: [:gbif, :bold]

  def latitude
    read_attribute_before_type_cast(:lat).round(10).to_f
  end

  def longitude
    read_attribute_before_type_cast(:lng).round(10).to_f
  end

  def self.headers
    %w(
      phylogatr_id
      accession
      source_id
      latitude
      longitude
      basis_of_record
      coordinate_uncertainty_in_meters
      issue
      flag
    )
  end

  def self.headers_tsv
    headers.join("\t") + "\n"
  end

  def to_str
    @str ||= self.class.headers.map {|a| self.send(a) }.join("\t")+"\n"
  end

  def self.accessions
    @accessions ||= Set.new(self.pluck(:accession))
  end

  def self.identifiers
    @identifiers ||= Set.new(self.pluck(:identifier))
  end

  # TODO: pluck(:field_number, :gene_symbol) so we can turn this into a hash
  def self.gbif_field_numbers
    @gbif_field_numbers ||= Hash[self.gbif.where.not(field_number: nil).distinct.pluck(:field_number, :genes)]
  end

  def self.gbif_catalog_numbers
    @gbif_catalog_numbers ||= Hash[self.gbif.where.not(catalog_number: nil).distinct.pluck(:catalog_number, :genes)]
  end

  # TODO: to do this, we need to know the
  #
  # def self.genes
  #   return @catalog_field_to_genes if defined?(@catalog_field_to_genes)
  #
  #   @catalog_field_to_genes = {
  #     :catalog => {
  #
  #   },
  #     :field => {
  #
  #     }
  #   }
  # end

  def duplicate?
    #TODO: this currently is handled by OccurrenceRecord but could be moved here...
    return false unless bold?

    if self.accession.present? && (Occurrence.accessions.include?(self.accession) || Occurrence.identifiers.include?(self.source_id))
      # duplicate
      true
    elsif(self.field_number.present? &&
       Occurrence.gbif_field_numbers.include?(self.field_number) &&
       Occurrence.gbif_field_numbers[self.field_number].split.include?(self.genes))
      $stderr.puts "duplicate warning: recognize bold record #{self.source_id} as duplicate because field number found"
      true
    elsif(self.catalog_number.present? &&
       Occurrence.gbif_catalog_numbers.include?(self.catalog_number) &&
       Occurrence.gbif_catalog_numbers[self.catalog_number].split.include?(self.genes))
      $stderr.puts "duplicate warning: recognize bold record #{self.source_id} as duplicate because catalog number found"
      true
    else
      # not duplicate
      false
    end
  end

  # not stored as a part of the model. it's just for the view
  def phylogatr_id
    a = accession.present? ? accession : '00000000'
    "#{a}_#{source_id}"
  end
end
