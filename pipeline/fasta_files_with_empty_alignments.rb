#!/usr/bin/env ruby

require 'find'

data_path = ARGV[0]

# if fa and afa ! exist, if cache key exists, write afa
# if fa and afa exist, if cache key exists, do nothing (OR write afa??)
# else align
Find.find(data_path) do |path|
  if FileTest.file?(path) && File.extname(path) == ".fa"
    afapath = path.sub(/fa$/, 'afa')

    if File.file?(afapath) && File.read(afapath).strip.empty?
      puts path
      puts afapath
    end
  end
end
