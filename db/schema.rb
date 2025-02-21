# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_02_20_203550) do

  create_table "files", force: :cascade do |t|
    t.integer "species_id"
    t.string "name"
    t.text "content", limit: 4294967295
    t.integer "num_seqs"
    t.integer "num_bytes"
    t.string "gene"
    t.index ["species_id"], name: "index_files_on_species_id"
  end

  create_table "occurrences", force: :cascade do |t|
    t.string "accession"
    t.string "source_id", limit: 8
    t.decimal "lat", precision: 15, scale: 10
    t.decimal "lng", precision: 15, scale: 10
    t.string "basis_of_record"
    t.integer "coordinate_uncertainty_in_meters"
    t.string "issue"
    t.string "different_genbank_species"
    t.integer "species_id"
    t.integer "source", default: 0
    t.string "field_number"
    t.string "catalog_number"
    t.string "identifier"
    t.date "event_date"
    t.text "genes"
    t.string "flag"
    t.index ["accession"], name: "index_occurrences_on_accession"
    t.index ["catalog_number"], name: "index_occurrences_on_catalog_number"
    t.index ["field_number"], name: "index_occurrences_on_field_number"
    t.index ["identifier"], name: "index_occurrences_on_identifier"
    t.index ["lat"], name: "index_occurrences_on_lat"
    t.index ["lng"], name: "index_occurrences_on_lng"
    t.index ["source"], name: "index_occurrences_on_source"
    t.index ["species_id"], name: "index_occurrences_on_species_id"
  end

  create_table "species", force: :cascade do |t|
    t.string "path"
    t.integer "total_seqs"
    t.integer "total_bytes"
    t.boolean "aligned"
    t.string "taxon_kingdom"
    t.string "taxon_phylum"
    t.string "taxon_class"
    t.string "taxon_order"
    t.string "taxon_family"
    t.string "taxon_genus"
    t.string "taxon_species"
    t.string "taxon_subspecies"
    t.string "different_genbank_species"
    t.index ["path"], name: "index_species_on_path"
    t.index ["taxon_class"], name: "index_species_on_taxon_class"
    t.index ["taxon_family"], name: "index_species_on_taxon_family"
    t.index ["taxon_genus"], name: "index_species_on_taxon_genus"
    t.index ["taxon_kingdom"], name: "index_species_on_taxon_kingdom"
    t.index ["taxon_order"], name: "index_species_on_taxon_order"
    t.index ["taxon_phylum"], name: "index_species_on_taxon_phylum"
    t.index ["taxon_species"], name: "index_species_on_taxon_species"
    t.index ["taxon_subspecies"], name: "index_species_on_taxon_subspecies"
  end

end
