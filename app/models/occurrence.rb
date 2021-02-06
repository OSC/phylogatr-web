class Occurrence < ActiveRecord::Base
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
      accession
      source_id
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

  def self.accessions
    @accessions ||= Set.new(self.pluck(:accession))
  end

  def self.identifiers
    @identifiers ||= Set.new(self.pluck(:identifier))
  end

  # TODO: pluck(:field_number, :gene_symbol) so we can turn this into a hash
  def self.gbif_field_numbers
    @gbif_field_numbers ||= Set.new(self.gbif.pluck(:field_number))
  end

  def self.gbif_catalog_numbers
    @gbif_catalog_numbers ||= Set.new(self.gbif.pluck(:catalog_number))
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
    # FIXME: instead of doing these queries for accessions, use a lookup
    #
    #
    # 1) array of accessions currently in use
    # 2)
    # 3)
    if bold?
      if self.accession.present? && (Occurrence.accessions.include?(self.accession) || Occurrence.identifiers.include?(self.source_id))
        # duplicate
        true
      else
        # TODO: do not do queries, do 1 query like this:
        # Occurrence.gbif.pluck(:field_number, :catalog_number, :gene_symbol)
        #
        # this means we need to add gene_symbol to the occurrences! Until we do we cannot filter these duplicates out.
        if(self.field_number.present? && Occurrence.gbif_field_numbers.include?(self.field_number))
          #TODO: does markercode i.e. gene_symbol match the gbif gene_symbol?
          # if it does it is a duplicate, else we want to keep it
          $stderr.puts "duplicate warning: recognize bold record #{self.source_id} as duplicate because field number found"
          true
        elsif(self.catalog_number.present? && Occurrence.gbif_catalog_numbers.include?(self.catalog_number))
          #TODO: does markercode i.e. gene_symbol match the gbif gene_symbol?
          # if it does it is a duplicate, else we want to keep it
          $stderr.puts "duplicate warning: recognize bold record #{self.source_id} as duplicate because catalog number found"
          true
        else
          # not duplicate
          false
        end
      end
    else
      #TODO: this currently is handled by OccurrenceRecord but could be moved here...
      # not duplicate
      false
    end
  end
end
