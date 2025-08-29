class AddTaxonOccurrenceSpeciesToGene < ActiveRecord::Migration[4.2]
  def change
    add_column :genes, :taxon_occurrence_species, :string
    add_index :genes, :taxon_occurrence_species
  end
end
