class DropGenesTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :genes
  end
end
