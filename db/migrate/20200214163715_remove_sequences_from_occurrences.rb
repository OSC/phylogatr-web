class RemoveSequencesFromOccurrences < ActiveRecord::Migration[4.2]
  def change
    remove_column :occurrences, :gene_name, :string
    remove_column :occurrences, :sequence, :text
    remove_column :occurrences, :sequence_aligned, :text
    remove_column :occurrences, :taxon_genbank_species, :string
  end
end
