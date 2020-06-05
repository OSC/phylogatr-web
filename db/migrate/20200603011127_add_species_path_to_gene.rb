class AddSpeciesPathToGene < ActiveRecord::Migration
  def change
    add_column :genes, :species_path, :string
  end
end
