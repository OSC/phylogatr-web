require 'csv'
require 'fileutils'

# first remove all the .fa files
# `find . -name "*.fa" -type f -delete`
Dir.chdir ARGV.first if ARGV.first

CSV.new(STDIN, col_sep: "\t").each do |row|
  path = row[1]
  accession = row[2]
  sequence = row[8]
  gbif_id = row[9]

  FileUtils.mkdir_p(File.dirname(path))
  File.write(path + ".fa", ">#{accession}_#{gbif_id}\n#{sequence}\n", mode: "a+")
end
