class AddIndexToSpeciesPath < ActiveRecord::Migration[4.2]
  def change
    add_index :occurrences, :species_path
  end
end
