class AddSubspeciesToOccurrence < ActiveRecord::Migration
  def change
    add_column :occurrences, :taxon_subspecies, :string
  end
end
