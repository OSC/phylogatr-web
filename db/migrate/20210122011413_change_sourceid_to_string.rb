class ChangeSourceidToString < ActiveRecord::Migration
  def change
    change_column :occurrences, :source_id, :string
  end
end
