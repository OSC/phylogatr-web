class RemoveOldSpeciesColsFromOccurrences < ActiveRecord::Migration[4.2]
  def change
    remove_column :occurrences, :species_max_seqs_per_gene
    remove_column :occurrences, :species_total_seqs
    remove_column :occurrences, :species_total_bytes
    remove_column :occurrences, :species_aligned
  end
end
