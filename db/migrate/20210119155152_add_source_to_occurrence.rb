class AddSourceToOccurrence < ActiveRecord::Migration[4.2]
  def change
    add_column :occurrences, :source, :integer, default: 0
    add_index :occurrences, :source
  end
end
