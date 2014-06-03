#!/usr/bin/ruby -W level=2

# "name": "knife-multi",
# "version": "0.0.1",
# "maintainer": "gtrummell@splunk.com"
# "description": "A utility script to run a knife command against several chef servers."

# require gems

require 'rubygems'
require 'mixlib/cli'
require 'json'
require 'pp'

# Set up command-line option parsing
class KifeMultiCLI
  include Mixlib::CLI

  option :config_file,
         :short => '-c CONFIG',
         :long => '--config CONFIG',
         :default => '../etc/knife-multi.json',
         :description => 'The configuration file to use',
         :required => false

  option :servers,
         :short => '-s SERVERS',
         :long => '--servers',
         :default => 'dev',
         :description => 'Regex for servers to execute against',
         :required => false

  option :encryption,
         :short => '-e',
         :long => '--encryption',
         :default => false,
         :description => 'Enable encryption when using data bag commands',
         :boolean => true,
         :required => false

  option :execute,
         :short => "-x \"COMMAND\"",
         :long => "--execute \"COMMAND\"",
         :default => 'status',
         :description => 'The command to execute',
         :required => false

  option :help,
         :short => '-h',
         :long => '--help',
         :description => 'Show this message',
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0
end

cli = KifeMultiCLI.new
cli.parse_options
config_file = JSON.parse(File.read(File.expand_path(cli.config[:config_file])))
if cli.config[:servers] == '*'
  servers = '.*'
else
  servers = cli.config[:servers]
end
execute = cli.config[:execute]

targets = config_file['servers'].map do |target|
  target if target['id'].match(/#{servers}/)
end

targets.each do |server|
  puts server['id']
end