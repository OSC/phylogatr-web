class AddColumnsToOccurrences < ActiveRecord::Migration
  def change
    add_column :occurrences, :basis_of_record, :string
    add_column :occurrences, :geodetic_datum, :string
    add_column :occurrences, :coordinate_uncertainty_in_meters, :integer
    add_column :occurrences, :issue, :string
  end
end
