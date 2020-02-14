class RenameSequencesToOccurrences < ActiveRecord::Migration
  def change
    rename_table :sequences, :occurrences
  end
end
