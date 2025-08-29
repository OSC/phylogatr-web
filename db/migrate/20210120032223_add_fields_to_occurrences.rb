class AddFieldsToOccurrences < ActiveRecord::Migration[4.2]
  def change
    change_table :occurrences do |t|
      t.string :field_number
      t.string :catalog_number
      t.string :identifier
      t.date :event_date

      t.index :field_number
      t.index :catalog_number
      t.index :identifier
    end
  end
end
