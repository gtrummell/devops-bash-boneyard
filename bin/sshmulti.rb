#!/usr/bin/env ruby -w

require 'mixlib/cli'
require 'net/ssh/multi'

# Set up CLI inputs
class CLI
  include Mixlib::CLI

  option :user,
         :short => '-u USER',
         :long => '--user USER',
         :description => 'Log into remote systems as USER, otherwise as current user',
         :default => ENV['USER'],
         :required => false

  option :hostlist,
         :short => '-h HOSTLIST',
         :long => '--hostlist HOSTLIST',
         :description => 'Space-delimited list of hosts or files containing a host on each line'

  option :com_spec,
         :short => '-c COMMANDS',
         :long => '--com_spec COMMANDS',
         :description => 'Issue COMMANDS.  If file, then parse and send.  Defaults to simple test',
         :default => '"echo -n "Successfully connected to "; sudo uname -a"',
         :required => false

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

# Parse command-line options
cli = CLI.new
cli.parse_options
user = cli.config[:user]
com_spec = cli.config[:com_spec]
verbose = cli.config[:verbose]

com_collection = ''
com_array = com_spec.split(' ')
com_array.each do |com|
  case com
    when File.file?(com)
      com_file = File.read(com)
      com_collection << ' '
      com_collection << com_file.gsub(/\n/, '; ')
    when (com == /".*?"/)
      com_collection << com
    when (com == /'.*?'/)
      com_collection << com
    else
      puts 'Invalid input'
  end
end

puts "Command Collection: #{com_collection}" if verbose

puts "Running as #{user}" if verbose
puts "Parsing command specificaton #{com_spec}" if verbose