class AddGenesTable < ActiveRecord::Migration
  def change
    create_table :genes do |t|
      t.string   "accession"
      t.string   "name"
      t.string   "fasta_file_prefix"
      t.string   "taxon_genbank_species"
      t.string   "genbank_source_file"

      # Rails 4: https://github.com/rails/rails/pull/21688 mediumblob:
      #
      #     t.binary :sequence, limit: 16777215
      #     t.binary :sequence_aligned, limit: 16777215
      #
      # Rails 5:
      #
      #     t.mediumblob "sequence"
      #     t.mediumblob "sequence_aligned"
      #
      # consider changing to blob later
      # text may provide more flexibility in short term
      t.text :sequence, limit: 16777215
      t.text :sequence_aligned, limit: 16777215
    end
  end
end
