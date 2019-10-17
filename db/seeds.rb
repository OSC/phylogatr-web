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
