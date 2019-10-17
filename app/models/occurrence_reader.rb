require 'csv'

class OccurrenceReader
  def associated_sequences(row)
    return [] unless row["associatedSequences"] && row["associatedSequences"].gsub(/[, ]/, "").present?

    row["associatedSequences"].scan /\w{2}\d{6}/
  end

  def occurrence_keys
    %w(gbifID kingdom phylum class order family genus species genericName acceptedScientificName speciesKey decimalLatitude decimalLongitude)
  end

  def each_occurrence(path)
    return to_enum(:each_occurrence, path)  unless block_given?

    CSV.foreach(path, col_sep: "\t", headers: true) do |row|
      associated_sequences(row).each do |accession|
        yield row.to_hash.slice(*occurrence_keys).merge("accession" => accession)
      end
    end
  end
end
