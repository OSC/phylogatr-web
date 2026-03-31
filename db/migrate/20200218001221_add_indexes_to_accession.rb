class AddIndexesToAccession < ActiveRecord::Migration[4.2]
  def change
    add_index :genes, :accession
    add_index :occurrences, :accession
  end
end
