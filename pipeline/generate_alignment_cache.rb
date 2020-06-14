#!/usr/bin/env ruby

require 'find'
require 'gdbm'
require 'digest'

data_path = ARGV[0]
cache_path = ARGV[1]

gdbm = GDBM.new(cache_path)

starting_length = gdbm.length

def checksum(path)
  Digest::SHA256.hexdigest(File.read(path))
end

def cache_afa(fapath, afapath, db)
  key = checksum(fapath)
  db[key] = File.read(afapath) unless db.has_key?(key)
end

Find.find(data_path) do |path|
  if FileTest.file?(path) && File.extname(path) == ".fa"
    afapath = path.sub(/fa$/, 'afa')
    cache_afa(path, afapath, gdbm) if FileTest.file?(afapath)
  end
end

puts "Added #{gdbm.length - starting_length} cache entries to #{cache_path}"

gdbm.close
