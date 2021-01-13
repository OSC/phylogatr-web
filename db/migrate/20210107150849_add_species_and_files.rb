class AddSpeciesAndFiles < ActiveRecord::Migration
  def change
    create_table :species do |t|
      t.string :path
      t.integer :total_seqs
      t.integer :total_bytes
      t.boolean :aligned
    end

    create_table :files do |t|
      t.belongs_to :species, index: true
      t.string :name
      t.text :content, limit: 4294967295 # equivalent to LONGTEXT
      t.integer :num_seqs
      t.integer :num_bytes
      t.string :gene
    end

    add_belongs_to :occurrences, :species, index: true
  end
end
