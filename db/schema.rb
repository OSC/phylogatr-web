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

ActiveRecord::Schema.define(version: 20210107164308) do

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
    t.string  "accession",                        limit: 255
    t.integer "gbif_id",                          limit: 8
    t.decimal "lat",                                          precision: 15, scale: 10
    t.decimal "lng",                                          precision: 15, scale: 10
    t.string  "taxon_kingdom",                    limit: 255
    t.string  "taxon_phylum",                     limit: 255
    t.string  "taxon_class",                      limit: 255
    t.string  "taxon_order",                      limit: 255
    t.string  "taxon_family",                     limit: 255
    t.string  "taxon_genus",                      limit: 255
    t.string  "taxon_species",                    limit: 255
    t.string  "taxon_subspecies",                 limit: 255
    t.string  "basis_of_record",                  limit: 255
    t.string  "geodetic_datum",                   limit: 255
    t.integer "coordinate_uncertainty_in_meters", limit: 4
    t.string  "issue",                            limit: 255
    t.string  "different_genbank_species",        limit: 255
    t.string  "species_path",                     limit: 255
    t.integer "species_id"
  end

  add_index "occurrences", ["accession"], name: "index_occurrences_on_accession"
  add_index "occurrences", ["lat"], name: "index_occurrences_on_lat"
  add_index "occurrences", ["lng"], name: "index_occurrences_on_lng"
  add_index "occurrences", ["species_id"], name: "index_occurrences_on_species_id"
  add_index "occurrences", ["species_path"], name: "index_occurrences_on_species_path"
  add_index "occurrences", ["taxon_class"], name: "index_occurrences_on_taxon_class"
  add_index "occurrences", ["taxon_family"], name: "index_occurrences_on_taxon_family"
  add_index "occurrences", ["taxon_genus"], name: "index_occurrences_on_taxon_genus"
  add_index "occurrences", ["taxon_kingdom"], name: "index_occurrences_on_taxon_kingdom"
  add_index "occurrences", ["taxon_order"], name: "index_occurrences_on_taxon_order"
  add_index "occurrences", ["taxon_phylum"], name: "index_occurrences_on_taxon_phylum"
  add_index "occurrences", ["taxon_species"], name: "index_occurrences_on_taxon_species"

  create_table "species", force: :cascade do |t|
    t.string  "path"
    t.integer "total_seqs"
    t.integer "total_bytes"
    t.boolean "aligned"
  end

end
