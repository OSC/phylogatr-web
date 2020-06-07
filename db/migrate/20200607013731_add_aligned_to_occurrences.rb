class AddAlignedToOccurrences < ActiveRecord::Migration
  def change
    add_column :occurrences, :species_aligned, :boolean 
    add_index :occurrences, :species_aligned
  end
end
