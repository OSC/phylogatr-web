#!/usr/bin/env ruby

require 'find'
require 'gdbm'
require 'digest'

data_path = ARGV[0]
cache_path = ARGV[1]

gdbm = GDBM.new(cache_path, 0666, GDBM::READER)

def checksum(path)
  Digest::SHA256.hexdigest(File.read(path))
end

# if fa and afa ! exist, if cache key exists, write afa
# if fa and afa exist, if cache key exists, do nothing (OR write afa??)
# else align
Find.find(data_path) do |path|
  if FileTest.file?(path) && File.extname(path) == ".fa"
    afapath = path.sub(/fa$/, 'afa')
    key = checksum(path)

    if File.file?(afapath)
      # do nothing
    elsif gdbm.has_key?(key)
      # write afa file
      File.write(afapath, gdbm[key])
      $stderr.puts "cache hit for #{path}, writing afa file"
    else
      puts %Q(time ./align_sequences.sh "#{path}")
    end
  end
end

gdbm.close
