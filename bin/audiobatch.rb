#!/usr/bin/env ruby

require 'ruby-sox'

# Hardcode input directories for now.
input_dirs = %w(~/Downloads ~/Music)

# Hardcode input formats for now.
input_exts = %w(wav)

# Go through each directory
input_files = []

input_dirs.each do |dir|
  input_exts.each do |ext|
    puts "Testing #{dir} for #{ext} files"
    Dir.glob(File.join(dir, "**/*.#{ext}")).each do |file|
      if File.file?(file)
        puts 'Adding ' + file
        input_files << file
      end
    end
  end
end

puts "Found input files:"
input_files.sort.each { |file| puts file }

threads = []
input_files.sort.each do |file|
  outfile = file.gsub(File.extname(file), '.aiff')
  puts "Starting conversion of #{file} to .aiff"
  if File.exist?(File.expand_path(outfile))
    puts "Skipped, file exists: #{outfile}"
  else
    sox = Sox::Cmd.new
    sox.add_input(file)
    sox.set_output(outfile)
    sox.run
    puts "Completed conversion of source to #{outfile}"
  end
end

puts "Conversion complete" if threads.join
