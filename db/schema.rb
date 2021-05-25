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

ActiveRecord::Schema.define(version: 20210525131547) do

  create_table "files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "species_id"
    t.string  "name"
    t.text    "content",    limit: 4294967295
    t.integer "num_seqs"
    t.integer "num_bytes"
    t.string  "gene"
    t.index ["species_id"], name: "index_files_on_species_id", using: :btree
  end

  create_table "occurrences", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "accession"
    t.string  "source_id"
    t.decimal "lat",                                            precision: 15, scale: 10
    t.decimal "lng",                                            precision: 15, scale: 10
    t.string  "basis_of_record"
    t.integer "coordinate_uncertainty_in_meters"
    t.string  "issue"
    t.string  "different_genbank_species"
    t.integer "species_id"
    t.integer "source",                                                                   default: 0
    t.string  "field_number"
    t.string  "catalog_number"
    t.string  "identifier"
    t.date    "event_date"
    t.text    "genes",                            limit: 65535
    t.string  "flag"
    t.index ["accession"], name: "index_occurrences_on_accession", using: :btree
    t.index ["catalog_number"], name: "index_occurrences_on_catalog_number", using: :btree
    t.index ["field_number"], name: "index_occurrences_on_field_number", using: :btree
    t.index ["identifier"], name: "index_occurrences_on_identifier", using: :btree
    t.index ["lat"], name: "index_occurrences_on_lat", using: :btree
    t.index ["lng"], name: "index_occurrences_on_lng", using: :btree
    t.index ["source"], name: "index_occurrences_on_source", using: :btree
    t.index ["species_id"], name: "index_occurrences_on_species_id", using: :btree
  end

  create_table "species", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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
    t.string  "different_genbank_species"
    t.index ["path"], name: "index_species_on_path", using: :btree
    t.index ["taxon_class"], name: "index_species_on_taxon_class", using: :btree
    t.index ["taxon_family"], name: "index_species_on_taxon_family", using: :btree
    t.index ["taxon_genus"], name: "index_species_on_taxon_genus", using: :btree
    t.index ["taxon_kingdom"], name: "index_species_on_taxon_kingdom", using: :btree
    t.index ["taxon_order"], name: "index_species_on_taxon_order", using: :btree
    t.index ["taxon_phylum"], name: "index_species_on_taxon_phylum", using: :btree
    t.index ["taxon_species"], name: "index_species_on_taxon_species", using: :btree
    t.index ["taxon_subspecies"], name: "index_species_on_taxon_subspecies", using: :btree
  end

end
