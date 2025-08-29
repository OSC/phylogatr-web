class AddSubspeciesToOccurrence < ActiveRecord::Migration[4.2]
  def change
    add_column :occurrences, :taxon_subspecies, :string
  end
end
