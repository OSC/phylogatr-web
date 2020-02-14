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

ActiveRecord::Schema.define(version: 20200214162752) do

  create_table "occurrences", force: :cascade do |t|
    t.string   "gbif_id"
    t.string   "accession"
    t.decimal  "lng",                   precision: 15, scale: 10
    t.decimal  "lat",                   precision: 15, scale: 10
    t.string   "taxon_kingdom"
    t.string   "taxon_phylum"
    t.string   "taxon_class"
    t.string   "taxon_order"
    t.string   "taxon_family"
    t.string   "taxon_genus"
    t.string   "taxon_species"
    t.string   "taxon_genbank_species"
    t.string   "gene_name"
    t.text     "sequence"
    t.text     "sequence_aligned"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

end
