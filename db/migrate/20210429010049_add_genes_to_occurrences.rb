class AddGenesToOccurrences < ActiveRecord::Migration[4.2]
  def change
    add_column :occurrences, :genes, :text
  end
end
