# frozen_string_literal: true

require 'pathname'

raise StandardError, 'need to set PHYLOGATR_GENBANK_DIR' if ENV['PHYLOGATR_GENBANK_DIR'].nil?

NIH = 'ftp.ncbi.nlm.nih.gov'
GENBANK = 'genbank'
PHYLOGATR_GENBANK_DIR = ENV['PHYLOGATR_GENBANK_DIR'].to_s

def remote_files
  `curl -L -q https://#{NIH}/#{GENBANK}`.each_line.map do |line|
    line.chomp
  end.map do |line|
    m = line.match(/href="(\w+\d+\.seq\.gz)"/)
    m.nil? ? nil : m[1]
  end.compact
end

def local_files
  Dir.glob('*.seq.gz')
end

def clean_genbank_file(f)
  p = Pathname.new(f)
  if p.file?
    if p.zero? || `gzip -t #{f} 2>&1`.chomp != ''
      puts "cleaning #{f} #{p.file? && p.zero?}"
      File.delete(f)
    end
  end
end

Dir.chdir(PHYLOGATR_GENBANK_DIR) do
  (remote_files - local_files).each do |file|
    clean_genbank_file(file)
  end.each do |file|
    puts "retrieving file #{file}"
    `wget -q --progress=dot https://#{NIH}/#{GENBANK}/#{file}`
  end
end
