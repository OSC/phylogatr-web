class RecreatedTablesToFixOrder < ActiveRecord::Migration
  def change
    create_table "occurrences", force: true do |t|
      t.string   "accession"
      t.integer  "gbif_id", limit: 8
      t.decimal  "lat",                              precision: 15, scale: 10
      t.decimal  "lng",                              precision: 15, scale: 10
      t.string   "taxon_kingdom"
      t.string   "taxon_phylum"
      t.string   "taxon_class"
      t.string   "taxon_order"
      t.string   "taxon_family"
      t.string   "taxon_genus"
      t.string   "taxon_species"
      t.string   "taxon_subspecies"
      t.string   "basis_of_record"
      t.string   "geodetic_datum"
      t.integer  "coordinate_uncertainty_in_meters"
      t.string   "issue"
    end

    create_table "genes", force: true do |t|
      t.string "accession"
      t.string "symbol"
      t.string "name"
      t.string "fasta_file_prefix"
      t.string "taxon_genbank_species"
      t.string "genbank_source_file"
      t.text   "sequence",              limit: 16777215
      t.text   "sequence_aligned",      limit: 16777215
    end
  end
end
