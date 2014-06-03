#!/bin/env ruby

require 'pp'
require 'rubygems'
require 'mixlib/cli'

# Set up CLI
class CLI
  include Mixlib::CLI

  option :directory,
         :short => '-d DIR',
         :long => '--dir DIR',
         :description => 'Directory to organize',
         :default => 'default.schema.json',
         :required => true

  option :verbose,
         :short => '-v',
         :long => '--verbose',
         :description => 'Run verbosely',
         :boolean => true,
         :required => false

  option :help,
         :short => '-h',
         :long => '--help',
         :description => 'Show this message',
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :required => false,
         :exit => 1

  def parse!(argv = ARGV)
    parse_options(argv)
  end

end

cli = CLI.new
cli.parse_options
directory = File.join(cli.config[:directory])
verbose = cli.config[:verbose]

# Get a list of directories
dir_array = Dir.glob(File.join(directory, '*')).select { |entry| File.directory?(entry) && !(entry == '.' || entry == '..') && entry.split('(', 2)[1].nil? }

# Loop through directories and fix them...
dir_array.each { |dir|
  # Search for filenames (they've already been renamed)
  # - Get a list of files, make sure to not use subtitle filenames... ignore subtitle files
  files = Dir.glob(File.join(dir, '*')).select { |file| File.file?(file) && file.split('.', 2)[1] != 'srt' }

  # - Fuxor with them to get a unique filename, leading to a dirname
  dirname = File.basename(files[0]).split('.', 2)[0]

  # Rename the directory
  pp "Moving from #{dir} ===TO===> #{File.join(File.expand_path('..', dir), dirname)}" if verbose
  FileUtils.move(dir, File.join(File.expand_path('..', dir), dirname))

# Exit the loop
}
pp 'Move complete'

# Quit the program