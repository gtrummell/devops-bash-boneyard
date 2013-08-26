#!/usr/bin/env ruby -W

require 'pp'
require 'rubygems'
require 'mixlib/cli'

# Set up CLI
class CLI
  include Mixlib::CLI

  option :schema_file,
         :short => '-s FILE',
         :long => '--schema FILE',
         :description => 'Schema filename',
         :default => 'default.schema.json',
         :required => true

  option :target_file,
         :short => '-t FILE',
         :long => '--target FILE',
         :description => 'Validation target filename',
         :default => 'target.json',
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
schema_file = cli.config[:schema_file]
target_file = cli.config[:target_file]
verbose = cli.config[:verbose]

puts schema_file
puts target_file
puts verbose