require 'csv'

class OccurrenceReader
  def associated_sequences(row)
    return [] unless row["associatedSequences"] && row["associatedSequences"].gsub(/[, ]/, "").present?

    row["associatedSequences"].scan /\w{2}\d{6}/
  end

  def occurrence_keys
    %w(gbifID decimalLatitude decimalLongitude kingdom phylum class order family genus species)
  end

  def occurrence_keys_normalized
    # 1:1 correspondence with keys above
    %i(gbif_id lat lng taxon_kingdom taxon_phylum taxon_class taxon_order taxon_family taxon_genus taxon_species)
  end

  def occurrence_key_lookup
    @occurrence_key_lookup ||= Hash[occurrence_keys.zip(occurrence_keys_normalized)]
  end

  def each_occurrence(path)
    return to_enum(:each_occurrence, path)  unless block_given?

    CSV.foreach(path, col_sep: "\t", headers: true) do |row|
      associated_sequences(row).each do |accession|
        yield occurrence_hash_from_row(row, accession)
      end
    end
  end

  def occurrence_hash_from_row(row, accession)
    row.to_hash.slice(*occurrence_keys).merge("accession" => accession).transform_keys { |key| occurrence_key_lookup.fetch(key, key) }
  end
end
