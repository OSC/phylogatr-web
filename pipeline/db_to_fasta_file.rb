#!/usr/bin/env ruby

require 'rexml/document'
require 'rexml/streamlistener'

# the benefit of this approach is that it works in Ruby 1.8.7+ with the standard
# library and thus can be run anywhere Ruby is installed

filename = ARGV[0] # 'Pantherophis-obsoletus-COI'
query = %Q(select id,sequence,fasta_file_prefix from genes where fasta_file_prefix = "#{filename}" order by accession;)

cmd = "mysql --defaults-file=/users/PZS0562/efranz/.my.cnf.phylogatrtest -X -e '#{query}'"

class Listener
  include REXML::StreamListener

  attr_reader :print_field_tag

  def tag_start(name, attrs)
    if name == "row"
      print ">"
    elsif name == "field"
      if attrs["name"] == "sequence"
        print "\n"
        @print_field_tag = true
      elsif attrs["name"] == "id"
        @print_field_tag = true
      end
    end
  end

  def text(text)
    print text if print_field_tag
  end

  def tag_end(name)
    if name == "row"
      print "\n"
    end

    @print_field_tag = false
  end
end

listener = Listener.new

IO.popen(cmd, "r") do |f|
  REXML::Document.parse_stream(f, listener)
end

# XML is a bunch of rows like:
#
# <row>
#   <field name="id">1234</field>
#   <field name="accession">MH274529</field>
#   <field name="sequence">cctataccttac....</field>
#   <field name="fasta_file_prefix">Pantherophis-obseletus...</field>
# </row>
