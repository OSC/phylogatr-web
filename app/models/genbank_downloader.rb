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
    clean!
    Dir.chdir(dir) do
      puts "Need to download #{files_needed.size} files."
      # FIXME: add retries here. you clean it above, dl a new bad one, and clean it below.
      files_needed.each do |file|
        puts "retrieving file #{file}"
        `wget -q --progress=dot https://#{NIH}/#{GENBANK}/#{file}`
      end
    end
    clean!
  end

  def remote_files
    `curl -L -q https://#{NIH}/#{GENBANK}`.each_line.map(&:chomp).map do |line|
      m = line.match(/href="(\w+\d+\.seq\.gz)"/)
      m.nil? ? nil : m[1]
    end.compact
  end

  def files_needed
    @files_needed ||= begin
      remote = remote_files.map { |s| s.chomp('.gz') }
      local = Dir.glob('*.{seq,seq.gz}').map { |s| s.chomp('.gz') }
      (remote - local).map { |s| "#{s}.gz" }
    end
  end

  def clean!
    Dir.chdir(dir) do
      Dir.glob('*.seq.gz').each do |gz|
        unless valid_gz?(gz)
          puts "removing file #{gz}. "
          File.delete(gz) unless valid_gz?(gz)
        end
      end
    end
  end

  def valid_gz?(file)
    p = Pathname.new(file)
    p.file? && !p.zero? && `gzip -t #{p} 2>&1`.chomp == ''
  end
end
