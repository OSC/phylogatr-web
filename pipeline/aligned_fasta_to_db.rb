#!/usr/bin/env ruby

fasta = STDIN.read

values = fasta.gsub("\n", "").strip.split(">").reject {|s| s.empty? }.map { |f|
  f =~ /^\w+-(\d+)(.*)$/
    "(#{$1}, '#{$2.downcase}')"
}

if values.empty?
  abort('muscle failed to produce valid FASTA for output')
else
  query = "INSERT INTO genes (id,sequence_aligned) VALUES #{values.join(',')}"+
          "ON DUPLICATE KEY UPDATE sequence_aligned=VALUES(sequence_aligned);"
  cmd = "mysql --defaults-file=$HOME/.my.cnf.phylogatrtest 2>&1"

  IO.popen(cmd, "r+") do |f|
    f.puts query
    f.close_write
    puts f.read
  end
end
