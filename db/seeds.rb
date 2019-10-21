# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require "active_support/all"

#FIXME: doing simple inefficient
# - 1 table, no indexes
# - retain all occurrence objects in memory till single write to database
#
sequences = {}

#FIXME: the CSV reader is SLOW. This is a prototype though, so it is unlikely
# that we will be using Ruby for the pipeline anyways. But one way to speed up
# is to use a subprocess that executes which filters out all records without
# associatedSequences i.e. via IO.popen
OccurrenceReader.new.each_occurrence("db/seed_data/occurrence.txt.filtered") do |occurrence|
  sequences[occurrence["accession"]] = Sequence.new(occurrence)
end

puts sequences.keys

# iterate over each sequence in the genbank sequences file
# filtering out those that are not in the specified accessions list
#
# FIXME: we need a better way to quickly retrieve unparsed sequences
# after processing a set of occurrences so we can do these together in
# batches; right now consecutive calls would reread through the sequence file
# the previous method was we have the list of accessions and we use the API to
# download the sequences for the given accessions, so we know which ones go
# together; using a copy of genbank files means we need to re-think this
# search
SequenceReader.new.each_sequence("db/seed_data/sequence.gb") do |s|
  if sequences.keys.include?(s.accession)
    # this sequence object should serve as a clonable copy
    newseq = sequences[s.accession].clone

    newseq.gene_name = s.gene
    newseq.sequence = s.seq
    newseq.taxon_genbank_species = s.species
    newseq.save
  end
end
