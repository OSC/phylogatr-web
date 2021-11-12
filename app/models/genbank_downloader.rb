# frozen_string_literal: true

require 'pathname'

# A simple class to download GenBank data from the NIH.
class GenbankDownloader
  attr_reader :dir

  NIH = 'ftp.ncbi.nlm.nih.gov'
  GENBANK = 'genbank'

  def initialize(dir)
    raise StandardError, 'only parameter has to be a valid directory' if dir.nil? || !Pathname.new(dir).directory?

    @dir = Pathname.new(dir)
  end

  def update!
    Dir.chdir(dir) do
      (remote_files - local_files).each do |file|
        clean_file(file)
      end.each do |file|
        puts "retrieving file #{file}"
        `wget -q --progress=dot https://#{NIH}/#{GENBANK}/#{file}`
      end
    end
  end

  def remote_files
    `curl -L -q https://#{NIH}/#{GENBANK}`.each_line.map(&:chomp).map do |line|
      m = line.match(/href="(\w+\d+\.seq\.gz)"/)
      m.nil? ? nil : m[1]
    end.compact
  end

  def local_files
    Dir.chdir(dir) do
      Dir.glob('*.seq.gz')
    end
  end

  def clean_file(file)
    p = Pathname.new(file)
    return unless p.file? && (p.zero? || `gzip -t #{f} 2>&1`.chomp != '')

    puts "cleaning #{f} #{p.file? && p.zero?}"
    File.delete(p.to_s)
  end
end
