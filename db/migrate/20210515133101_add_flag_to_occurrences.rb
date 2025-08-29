class AddFlagToOccurrences < ActiveRecord::Migration[4.2]
  def change
    add_column :occurrences, :flag, :string
  end
end
