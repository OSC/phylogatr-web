class RenameGbifidToSourceid < ActiveRecord::Migration[4.2]
  def change
    rename_column :occurrences, :gbif_id, :source_id
  end
end
