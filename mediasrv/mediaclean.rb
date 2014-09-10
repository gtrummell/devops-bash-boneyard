#!/usr/bin/env ruby

require 'fileutils'
require 'logger'

# Set the home location of Media files
media_home = '/gbuffalo/TV'

# Get a listing of all files in Media
media_files = Dir.glob(File.join(media_home, '/**/*'))

# Define conditions
conditions = %w{.*cifs.* .*DS.*Store.* .*[\.-]orig.* .*\.nfo}

# Create method to test and remove a file if it matches conditions
def rm_file(file, condition)
  if file =~ /#{condition}/
    FileUtils.rm_f(file)
    puts file + ' removed, matched condition ' + condition
  else
    puts file + ' skipped, did not match condition ' + condition
  end
end

# Remove any CIFS files.
media_files.each do |file|
  conditions.each do |condition|
    rm_file(file, condition)
  end
end
