class AddGenesToOccurrences < ActiveRecord::Migration
  def change
    add_column :occurrences, :genes, :text
  end
end
