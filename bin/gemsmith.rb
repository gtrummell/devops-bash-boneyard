#!/usr/bin/env ruby

# Clear workspaces on executor nodes.
# Some stuff needs to be preconfigured, see below.

# Require gems
require 'mixlib/cli'
require 'pp'
require File.expand_path('../../scripts/lib/gem-smith')

# Set up CLI inputs
class CLI
  include Mixlib::CLI

  option :command,
         :short => '-c COMMAND',
         :long => '--command COMMAND',
         :description => 'Action for GemSmith to carry out',
         :boolean => false,
         :required => true

  option :gemfile,
         :short => '-f GEMFILE',
         :long => '--gemfile GEMFILE',
         :default => './Gemfile',
         :description => 'The path to your Gemfile',
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
         :exit => 0

  def parse!(argv = ARGV)
    parse_options(argv)
  end
end

# Parse command-line options
cli = CLI.new
cli.parse_options
command = cli.config[:command]
gemfile = File.expand_path(cli.config[:gemfile])
verbose = cli.config[:verbose]

# Initialize the project
pp "Loading #{gemfile}" if verbose
project = GemSmith.new(gemfile)
project.scan_project

# Search for gems in the Gemfile
in_gemfile = project.list_gemfile

# Search for gems in files
in_files = project.list_required

case command
  when 'gemfile'
    pp 'Show gems in the Gemfile'
    pp in_gemfile
  when 'required'
    pp 'Show gems in the project'
    pp in_files
  when 'unused'
    pp 'Show unused gems in the Gemfile'
    pp (in_gemfile - in_files)
  when 'nogemfile'
    pp 'Show gems in the project, not in the Gemfile'
    pp (in_files - in_gemfile)
  else
    raise "A command must be specified: gemfile, required, unused, or nogemfile.  Your command: #{command}"
end