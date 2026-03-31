class AddSpeciesPathToGene < ActiveRecord::Migration[4.2]
  def change
    add_column :genes, :species_path, :string
  end
end
