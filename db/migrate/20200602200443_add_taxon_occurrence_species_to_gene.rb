class AddTaxonOccurrenceSpeciesToGene < ActiveRecord::Migration
  def change
    add_column :genes, :taxon_occurrence_species, :string
    add_index :genes, :taxon_occurrence_species
  end
end
