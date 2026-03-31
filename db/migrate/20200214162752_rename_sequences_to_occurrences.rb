class RenameSequencesToOccurrences < ActiveRecord::Migration[4.2]
  def change
    rename_table :sequences, :occurrences
  end
end
