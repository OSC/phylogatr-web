class AddIndexes < ActiveRecord::Migration
  def change
    change_table(:occurrences) do |t|
      t.index :lat
      t.index :lng
      t.index :taxon_kingdom
      t.index :taxon_phylum
      t.index :taxon_class
      t.index :taxon_order
      t.index :taxon_family
      t.index :taxon_genus
      t.index :taxon_species
    end

    add_index :genes, [:fasta_file_prefix, :accession]
  end
end
