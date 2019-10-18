require 'csv'

class OccurrenceReader
  def associated_sequences(row)
    return [] unless row["associatedSequences"] && row["associatedSequences"].gsub(/[, ]/, "").present?

    row["associatedSequences"].scan /\w{2}\d{6}/
  end

  # map GBIF key names to symbols for the column names in database
  def occurrence_keys_lookup
    {
      "gbifID" => :gbif_id,
      "decimalLatitude" => :lat,
      "decimalLongitude" => :lng,
      "kingdom" => :taxon_kingdom,
      "phylum" => :taxon_phylum,
      "class" => :taxon_class,
      "order" => :taxon_order,
      "family" => :taxon_family,
      "genus" => :taxon_genus,
      "species" => :taxon_species
    }
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
    row.to_hash.slice(*(occurrence_keys_lookup.keys)).merge("accession" => accession).transform_keys { |key| occurrence_keys_lookup.fetch(key, key) }
  end
end
