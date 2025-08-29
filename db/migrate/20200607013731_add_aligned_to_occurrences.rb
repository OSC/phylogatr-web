class AddAlignedToOccurrences < ActiveRecord::Migration[4.2]
  def change
    add_column :occurrences, :species_aligned, :boolean 
    add_index :occurrences, :species_aligned
  end
end
