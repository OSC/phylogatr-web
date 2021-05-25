class AddDifferentGenbankSpeciesToSpeciesTable < ActiveRecord::Migration[5.0]
  def change
    add_column :species, :different_genbank_species, :string
  end
end
