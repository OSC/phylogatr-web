# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require "active_support/all"

accessions = []
OccurrenceReader.new.each_occurrence("db/occurrence.txt") do |row|
  puts row.slice(*%w(gbifID species accession))
  accessions << row["accession"]
end

puts accessions

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
#
# FIXME: lazy enumeration?
SequenceReader.new.each_sequence("db/sequence.gb").select {|s|
  accessions.include?(s.accession)
}.each { |s|
  puts "#{s.accession} - #{s.gene_name} - #{s.gene} - #{s.gb.definition}"
}
