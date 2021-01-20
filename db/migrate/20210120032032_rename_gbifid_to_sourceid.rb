class RenameGbifidToSourceid < ActiveRecord::Migration
  def change
    rename_column :occurrences, :gbif_id, :source_id
  end
end
