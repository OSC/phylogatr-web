class RemoveGeodeticDatumFromOccurrences < ActiveRecord::Migration
  def change
    remove_column :occurrences, :geodetic_datum
  end
end
