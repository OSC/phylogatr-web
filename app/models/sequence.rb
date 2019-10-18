class Sequence < ActiveRecord::Base
  # FIXME: this causes crash :-(
  #
  # alias_attribute :gbifID, :gbif_id
  # alias_attribute :decimalLatitude, :lat
  # alias_attribute :decimalLongitude, :lng

  # # currently ignoring subgenus
  # %w(kingdom phylum class order family genus species).each do |taxon|
  #   alias_attribute taxon.to_sym, "taxon_#{taxon}".to_sym
  # end
end

