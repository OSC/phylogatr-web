class AddSymbolToGenes < ActiveRecord::Migration
  def change
    add_column :genes, :symbol, :string
  end
end
