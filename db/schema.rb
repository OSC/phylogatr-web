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

ActiveRecord::Schema.define(version: 20210119155152) do

  create_table "files", force: :cascade do |t|
    t.integer "species_id"
    t.string  "name"
    t.text    "content",    limit: 4294967295
    t.integer "num_seqs"
    t.integer "num_bytes"
    t.string  "gene"
  end

  add_index "files", ["species_id"], name: "index_files_on_species_id"

  create_table "occurrences", force: :cascade do |t|
    t.string  "accession"
    t.integer "gbif_id",                          limit: 8
    t.decimal "lat",                                        precision: 15, scale: 10
    t.decimal "lng",                                        precision: 15, scale: 10
    t.string  "basis_of_record"
    t.string  "geodetic_datum"
    t.integer "coordinate_uncertainty_in_meters"
    t.string  "issue"
    t.string  "different_genbank_species"
    t.integer "species_id"
    t.integer "source",                                                               default: 0
  end

  add_index "occurrences", ["accession"], name: "index_occurrences_on_accession"
  add_index "occurrences", ["lat"], name: "index_occurrences_on_lat"
  add_index "occurrences", ["lng"], name: "index_occurrences_on_lng"
  add_index "occurrences", ["source"], name: "index_occurrences_on_source"
  add_index "occurrences", ["species_id"], name: "index_occurrences_on_species_id"

  create_table "species", force: :cascade do |t|
    t.string  "path"
    t.integer "total_seqs"
    t.integer "total_bytes"
    t.boolean "aligned"
    t.string  "taxon_kingdom"
    t.string  "taxon_phylum"
    t.string  "taxon_class"
    t.string  "taxon_order"
    t.string  "taxon_family"
    t.string  "taxon_genus"
    t.string  "taxon_species"
    t.string  "taxon_subspecies"
  end

  add_index "species", ["path"], name: "index_species_on_path"
  add_index "species", ["taxon_class"], name: "index_species_on_taxon_class"
  add_index "species", ["taxon_family"], name: "index_species_on_taxon_family"
  add_index "species", ["taxon_genus"], name: "index_species_on_taxon_genus"
  add_index "species", ["taxon_kingdom"], name: "index_species_on_taxon_kingdom"
  add_index "species", ["taxon_order"], name: "index_species_on_taxon_order"
  add_index "species", ["taxon_phylum"], name: "index_species_on_taxon_phylum"
  add_index "species", ["taxon_species"], name: "index_species_on_taxon_species"
  add_index "species", ["taxon_subspecies"], name: "index_species_on_taxon_subspecies"

end
