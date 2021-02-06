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

ActiveRecord::Schema.define(version: 20210122011413) do

  create_table "files", force: :cascade do |t|
    t.integer "species_id", limit: 4
    t.string  "name",       limit: 255
    t.text    "content",    limit: 4294967295
    t.integer "num_seqs",   limit: 4
    t.integer "num_bytes",  limit: 4
    t.string  "gene",       limit: 255
  end

  add_index "files", ["species_id"], name: "index_files_on_species_id", using: :btree

  create_table "occurrences", force: :cascade do |t|
    t.string  "accession",                        limit: 255
    t.string  "source_id",                        limit: 255
    t.decimal "lat",                                          precision: 15, scale: 10
    t.decimal "lng",                                          precision: 15, scale: 10
    t.string  "basis_of_record",                  limit: 255
    t.string  "geodetic_datum",                   limit: 255
    t.integer "coordinate_uncertainty_in_meters", limit: 4
    t.string  "issue",                            limit: 255
    t.string  "different_genbank_species",        limit: 255
    t.integer "species_id",                       limit: 4
    t.integer "source",                           limit: 4,                             default: 0
    t.string  "field_number",                     limit: 255
    t.string  "catalog_number",                   limit: 255
    t.string  "identifier",                       limit: 255
    t.date    "event_date"
  end

  add_index "occurrences", ["accession"], name: "index_occurrences_on_accession", using: :btree
  add_index "occurrences", ["catalog_number"], name: "index_occurrences_on_catalog_number", using: :btree
  add_index "occurrences", ["field_number"], name: "index_occurrences_on_field_number", using: :btree
  add_index "occurrences", ["identifier"], name: "index_occurrences_on_identifier", using: :btree
  add_index "occurrences", ["lat"], name: "index_occurrences_on_lat", using: :btree
  add_index "occurrences", ["lng"], name: "index_occurrences_on_lng", using: :btree
  add_index "occurrences", ["source"], name: "index_occurrences_on_source", using: :btree
  add_index "occurrences", ["species_id"], name: "index_occurrences_on_species_id", using: :btree

  create_table "species", force: :cascade do |t|
    t.string  "path",             limit: 255
    t.integer "total_seqs",       limit: 4
    t.integer "total_bytes",      limit: 4
    t.boolean "aligned"
    t.string  "taxon_kingdom",    limit: 255
    t.string  "taxon_phylum",     limit: 255
    t.string  "taxon_class",      limit: 255
    t.string  "taxon_order",      limit: 255
    t.string  "taxon_family",     limit: 255
    t.string  "taxon_genus",      limit: 255
    t.string  "taxon_species",    limit: 255
    t.string  "taxon_subspecies", limit: 255
  end

  add_index "species", ["path"], name: "index_species_on_path", using: :btree
  add_index "species", ["taxon_class"], name: "index_species_on_taxon_class", using: :btree
  add_index "species", ["taxon_family"], name: "index_species_on_taxon_family", using: :btree
  add_index "species", ["taxon_genus"], name: "index_species_on_taxon_genus", using: :btree
  add_index "species", ["taxon_kingdom"], name: "index_species_on_taxon_kingdom", using: :btree
  add_index "species", ["taxon_order"], name: "index_species_on_taxon_order", using: :btree
  add_index "species", ["taxon_phylum"], name: "index_species_on_taxon_phylum", using: :btree
  add_index "species", ["taxon_species"], name: "index_species_on_taxon_species", using: :btree
  add_index "species", ["taxon_subspecies"], name: "index_species_on_taxon_subspecies", using: :btree

end
