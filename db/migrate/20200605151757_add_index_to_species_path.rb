class AddIndexToSpeciesPath < ActiveRecord::Migration
  def change
    add_index :occurrences, :species_path
  end
end
