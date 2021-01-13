class DropGenesTable < ActiveRecord::Migration
  def change
    drop_table :genes
  end
end
