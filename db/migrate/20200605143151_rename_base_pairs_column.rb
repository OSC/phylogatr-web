class RenameBasePairsColumn < ActiveRecord::Migration
  def change
    rename_column :occurrences, :species_total_base_pairs, :species_total_bytes
  end
end
