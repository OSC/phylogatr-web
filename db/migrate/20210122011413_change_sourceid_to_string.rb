class ChangeSourceidToString < ActiveRecord::Migration[4.2]
  def change
    change_column :occurrences, :source_id, :string
  end
end
