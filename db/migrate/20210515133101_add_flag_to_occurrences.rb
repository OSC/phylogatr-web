class AddFlagToOccurrences < ActiveRecord::Migration
  def change
    add_column :occurrences, :flag, :string
  end
end
