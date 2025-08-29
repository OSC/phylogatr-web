class AddSymbolToGenes < ActiveRecord::Migration[4.2]
  def change
    add_column :genes, :symbol, :string
  end
end
