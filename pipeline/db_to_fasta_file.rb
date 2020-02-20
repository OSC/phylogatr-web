#!/usr/bin/env ruby

require 'rexml/document'
require 'rexml/xpath'

filename = ARGV[0] # 'Pantherophis-obsoletus-COI'
query = %Q(select id,accession,sequence,fasta_file_prefix from genes where fasta_file_prefix = "#{filename}" order by accession;)

xml = `mysql --defaults-file=/users/PZS0562/efranz/.my.cnf.phylogatrtest -X -e '#{query}'`

# XML is a bunch of rows like:
#
# <row>
#   <field name="id">1234</field>
#   <field name="accession">MH274529</field>
#   <field name="sequence">cctataccttac....</field>
#   <field name="fasta_file_prefix">Pantherophis-obseletus...</field>
# </row>

# output formated FASTA file
doc = REXML::Document.new(xml)
fields = REXML::XPath.match(doc, '//field/text()')
puts fields.each_slice(4).map {|x| ">#{x[1]}-#{x[0]}\n#{x[2]}" }.join("\n")
