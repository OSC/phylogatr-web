# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require "active_support/all"
require "open3"
require "csv"

occurrences_path = "db/seed_data/panthropis.seq.idx.occurrences"

# generated using:
# inv write-genes ../db/seed_data/panthropis.seq.idx.occurrences test/fixtures/panthropis.seq ../db/seed_data
genes_path = "db/seed_data/panthropis.seq.genes.tsv"


#FIXME: CSV is slow! but fine for now... also want to read in chunks i.e. read_line.slice(1000)
Occurrence.transaction do
  columns = [:accession, :gbif_id, :lat, :lng, :taxon_kingdom, :taxon_phylum, :taxon_class, :taxon_order, :taxon_family, :taxon_genus, :taxon_species, :taxon_subspecies, :basis_of_record, :geodetic_datum, :coordinate_uncertainty_in_meters, :issue]

  # TODO: this didn't work :-P
  #  occurrences = CSV.read(occurrences_path, col_sep: "\t", headers: columns).map(&:to_h)

  occurrences = File.read(occurrences_path).strip().split("\n").map { |values|
    Hash[columns.zip(values.split("\t"))].symbolize_keys
  }

  Occurrence.import columns, occurrences, validate: false
end

Gene.transaction do
  columns = [:accession, :symbol, :name, :fasta_file_prefix, :taxon_genbank_species, :genbank_source_file, :sequence]

  genes = File.read(genes_path).strip().split("\n").map { |values|
    Hash[columns.zip(values.split("\t"))].symbolize_keys
  }

  Gene.import columns, genes, validate: false
end
