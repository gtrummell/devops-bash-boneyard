#!/usr/bin/env ruby

aif_ext = Dir.glob('/Volumes/Media/Music/Native/**/*.aif')

aif_ext.each do |file|
  puts 'Renaming ' + file + ' to ' + file.gsub(File.extname(file), '.aiff')
  File.rename(file, file.gsub(File.extname(file), '.aiff'))
end