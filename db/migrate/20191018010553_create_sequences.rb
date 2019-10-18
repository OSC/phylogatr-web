class CreateSequences < ActiveRecord::Migration
  def change
    create_table :sequences do |t|
      t.string :gbif_id
      t.string :accession
      t.decimal :lng, precision: 15, scale: 10
      t.decimal :lat, precision: 15, scale: 10
      t.string :taxon_kingdom
      t.string :taxon_phylum
      t.string :taxon_class
      t.string :taxon_order
      t.string :taxon_family
      t.string :taxon_genus
      t.string :taxon_species
      t.string :taxon_genbank_species
      t.string :gene_name
      t.text :sequence
      t.text :sequence_aligned

      t.timestamps null: false
    end
  end
end
