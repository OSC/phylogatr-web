# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200218001221) do

  create_table "genes", force: :cascade do |t|
    t.string "accession"
    t.string "symbol"
    t.string "name"
    t.string "fasta_file_prefix"
    t.string "taxon_genbank_species"
    t.string "genbank_source_file"
    t.text   "sequence",              limit: 16777215
    t.text   "sequence_aligned",      limit: 16777215
  end

  add_index "genes", ["accession"], name: "index_genes_on_accession"
  add_index "genes", ["fasta_file_prefix", "accession"], name: "index_genes_on_fasta_file_prefix_and_accession"

  create_table "occurrences", force: :cascade do |t|
    t.string  "accession"
    t.integer "gbif_id",                          limit: 8
    t.decimal "lat",                                        precision: 15, scale: 10
    t.decimal "lng",                                        precision: 15, scale: 10
    t.string  "taxon_kingdom"
    t.string  "taxon_phylum"
    t.string  "taxon_class"
    t.string  "taxon_order"
    t.string  "taxon_family"
    t.string  "taxon_genus"
    t.string  "taxon_species"
    t.string  "taxon_subspecies"
    t.string  "basis_of_record"
    t.string  "geodetic_datum"
    t.integer "coordinate_uncertainty_in_meters"
    t.string  "issue"
  end

  add_index "occurrences", ["accession"], name: "index_occurrences_on_accession"
  add_index "occurrences", ["lat"], name: "index_occurrences_on_lat"
  add_index "occurrences", ["lng"], name: "index_occurrences_on_lng"
  add_index "occurrences", ["taxon_class"], name: "index_occurrences_on_taxon_class"
  add_index "occurrences", ["taxon_family"], name: "index_occurrences_on_taxon_family"
  add_index "occurrences", ["taxon_genus"], name: "index_occurrences_on_taxon_genus"
  add_index "occurrences", ["taxon_kingdom"], name: "index_occurrences_on_taxon_kingdom"
  add_index "occurrences", ["taxon_order"], name: "index_occurrences_on_taxon_order"
  add_index "occurrences", ["taxon_phylum"], name: "index_occurrences_on_taxon_phylum"
  add_index "occurrences", ["taxon_species"], name: "index_occurrences_on_taxon_species"

end
