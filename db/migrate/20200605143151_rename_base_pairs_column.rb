class RenameBasePairsColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :occurrences, :species_total_base_pairs, :species_total_bytes
  end
end
