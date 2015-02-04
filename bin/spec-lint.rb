#!/usr/bin/env ruby

# Enumerate RPM Spec Files
specfile_list = File.join(ENV['HOME'], 'src', 'bandpage', 'bandpage-config', 'build', '*.spec')
spec_files = Dir.glob(specfile_list)

# Read in each Spec file and get all paths.
# This is going to be lines that start with '/' as well as lines that start with '%'
path_lines = []

spec_files.each do |spec_file|
  File.read(spec_file).each_line do |line|
    line.select do |line|
      line.gsub(/^%.*\) \//, '')
      path_lines << line if line == /^\/.*/
    end
  end
end

