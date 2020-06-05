class AddGenbankColsToOccurrences < ActiveRecord::Migration
  def change
    add_column :occurrences, :different_genbank_species, :string
    add_column :occurrences, :species_path, :string
    add_column :occurrences, :species_max_seqs_per_gene, :integer
    add_column :occurrences, :species_total_seqs, :integer
    add_column :occurrences, :species_total_base_pairs, :integer

    # will query against this if user sets threshold > 3
    add_index :occurrences, :species_max_seqs_per_gene
  end
end
