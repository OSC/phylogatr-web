require 'csv'
require 'fileutils'

# first remove all the .fa files
# `find . -name "*.fa" -type f -delete`
Dir.chdir ARGV.first if ARGV.first

CSV.new(STDIN, col_sep: "\t").each do |row|
  path = row[0]
  accession = row[1]
  sequence = row[7]
  gbif_id = row[8]

  FileUtils.mkdir_p(File.dirname("./#{path}"))
  File.write("./#{path}.fa", ">#{accession}_#{gbif_id}\n#{sequence}\n", mode: "a+")
end
