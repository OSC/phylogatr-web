class RemoveGeodeticDatumFromOccurrences < ActiveRecord::Migration[4.2]
  def change
    remove_column :occurrences, :geodetic_datum
  end
end
