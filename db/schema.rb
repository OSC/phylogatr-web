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

ActiveRecord::Schema.define(version: 20200605151757) do

  create_table "genes", force: :cascade do |t|
    t.string "accession",                limit: 255
    t.string "symbol",                   limit: 255
    t.string "name",                     limit: 255
    t.string "fasta_file_prefix",        limit: 255
    t.string "taxon_genbank_species",    limit: 255
    t.string "genbank_source_file",      limit: 255
    t.text   "sequence",                 limit: 16777215
    t.text   "sequence_aligned",         limit: 16777215
    t.string "taxon_occurrence_species", limit: 255
    t.string "species_path",             limit: 255
  end

  add_index "genes", ["accession"], name: "index_genes_on_accession", using: :btree
  add_index "genes", ["fasta_file_prefix", "accession"], name: "index_genes_on_fasta_file_prefix_and_accession", using: :btree
  add_index "genes", ["taxon_occurrence_species"], name: "index_genes_on_taxon_occurrence_species", using: :btree

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
    t.integer "species_max_seqs_per_gene",        limit: 4
    t.integer "species_total_seqs",               limit: 4
    t.integer "species_total_bytes",              limit: 4
  end

  add_index "occurrences", ["accession"], name: "index_occurrences_on_accession", using: :btree
  add_index "occurrences", ["lat"], name: "index_occurrences_on_lat", using: :btree
  add_index "occurrences", ["lng"], name: "index_occurrences_on_lng", using: :btree
  add_index "occurrences", ["species_max_seqs_per_gene"], name: "index_occurrences_on_species_max_seqs_per_gene", using: :btree
  add_index "occurrences", ["species_path"], name: "index_occurrences_on_species_path", using: :btree
  add_index "occurrences", ["taxon_class"], name: "index_occurrences_on_taxon_class", using: :btree
  add_index "occurrences", ["taxon_family"], name: "index_occurrences_on_taxon_family", using: :btree
  add_index "occurrences", ["taxon_genus"], name: "index_occurrences_on_taxon_genus", using: :btree
  add_index "occurrences", ["taxon_kingdom"], name: "index_occurrences_on_taxon_kingdom", using: :btree
  add_index "occurrences", ["taxon_order"], name: "index_occurrences_on_taxon_order", using: :btree
  add_index "occurrences", ["taxon_phylum"], name: "index_occurrences_on_taxon_phylum", using: :btree
  add_index "occurrences", ["taxon_species"], name: "index_occurrences_on_taxon_species", using: :btree

end
