class MoveTaxonToSpecies < ActiveRecord::Migration
  def change
    change_table :occurrences do |t|
      t.remove :taxon_kingdom
      t.remove :taxon_phylum
      t.remove :taxon_class
      t.remove :taxon_order
      t.remove :taxon_family
      t.remove :taxon_genus
      t.remove :taxon_species
      t.remove :taxon_subspecies
      t.remove :species_path
    end

    change_table :species do |t|
      t.column :taxon_kingdom, :string
      t.column :taxon_phylum, :string
      t.column :taxon_class, :string
      t.column :taxon_order, :string
      t.column :taxon_family, :string
      t.column :taxon_genus, :string
      t.column :taxon_species, :string
      t.column :taxon_subspecies, :string

      t.index :taxon_kingdom
      t.index :taxon_phylum
      t.index :taxon_class
      t.index :taxon_order
      t.index :taxon_family
      t.index :taxon_genus
      t.index :taxon_species
      t.index :taxon_subspecies

      t.index :path
    end
  end
end