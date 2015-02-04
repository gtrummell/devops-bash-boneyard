#!/usr/bin/env ruby

require 'fileutils'
require 'ruby-sox'

# Converts a defined set of audio files into aiff.

src_dir = '/gbuffalo/Music/Native/**/*'
src_exts = %w{m4a mp3 flac wav}

src_files = []
Dir.glob(src_dir).select do |entry|
  entry_ext = entry.split('.').last
  next if File.directory?(entry)
  next unless src_exts.include?(entry_ext)
  src_files << {entry: entry.gsub(/\.#{entry_ext}$/, ''), ext: entry_ext }
end

memlog = []

threads = []
src_files.each do |file|
  threads << Thread.new do
    src_file = File.expand_path(file[:entry].to_s + '.' + file[:ext].to_s)
    new_file = File.new(file[:entry].to_s + '.aiff')
    begin
      memlog << 'Converting ' + src_file + ' to ' + new_file
      sox_conv = Sox::Cmd.new(:sox_conv)
      sox_conv.add_input(src_file)
      sox_conv.set_output(new_file)
      sox_conv.run
      new_file.close_write
    rescue
      memlog << 'Got sox error ' + $?
      next
    end
  end
end

threads.join
puts memlog
