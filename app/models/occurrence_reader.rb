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

  # iterate over each sequence in the genbank sequences file
  # filtering out those that are not in the specified accessions list
  #
  # FIXME: we need a better way to quickly retrieve unparsed sequences
  # after processing a set of occurrences so we can do these together in
  # batches; right now consecutive calls would reread through the sequence file
  # the previous method was we have the list of accessions and we use the API to
  # download the sequences for the given accessions, so we know which ones go
  # together; using a copy of genbank files means we need to re-think this
  # search
  def each_sequence(path, accessions)
  end
end
