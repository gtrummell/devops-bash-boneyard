#!/usr/bin/env ruby

# List all Jenkins objects, extract them to files, and create manifests

# Require gems
require 'mixlib/cli'

#require File.expand_path(File.join(ENV['HOME'], "Source/stackmakr/tools/lib/stackutil.rb"))
require File.expand_path('../lib/license_data_bag')

include FileUtils

# Initialize the logger
#@logger = ::StackUtil::Logger.instance

# Set up CLI inputs
class Sl2cdbCLI
  include Mixlib::CLI

  option :chef_config,
         :short => '-c CHEF_CONFIG',
         :long => '--chef-config CHEF_CONFIG',
         :default => File.exist?(File.join(ENV['HOME'], '.chef', 'knife.rb')) ||
             File.exist?(File.join('etc', 'chef', 'knife.rb')) ||
             File.exist?(File.join('etc', 'chef', 'chef.rb')),
         :description => 'Path to the chef configuration file',
         :required => false

  option :secret,
         :short => '-s SECRET_FILE',
         :long => '--secret-file SECRET_FILE',
         :default => File.join(Dir.pwd, 'splunk.license'),
         :description => 'Path to the license file',
         :required => false

  option :license_file,
         :short => '-l LICENSE_FILE',
         :long => '--license LICENSE_FILE',
         :default => File.join(Dir.pwd, 'splunk.license'),
         :description => 'Path to the license file',
         :required => false

  option :verbose,
         :short => '-V',
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
sl2cdb_cli = Sl2cdbCLI.new
sl2cdb_cli.parse!

chef_config = sl2cdb_cli.config[:chef_config]
license_file = sl2cdb_cli.config[:license_file]
verbose = sl2cdb_cli.config[:verbose]

@logger.info("Adding license #{license_file} to chef server specified in #{chef_config}") if verbose

ldb = LicenseDataBag.new(license_file, chef_config)

Dir.mkdir('~/tmp')
ldb.to_plain_databag('~/tmp/test-bag.json')

