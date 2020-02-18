class AddIndexesToAccession < ActiveRecord::Migration
  def change
    add_index :genes, :accession
    add_index :occurrences, :accession
  end
end
