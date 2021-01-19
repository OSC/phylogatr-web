class AddSourceToOccurrence < ActiveRecord::Migration
  def change
    add_column :occurrences, :source, :integer, default: 0
    add_index :occurrences, :source
  end
end
