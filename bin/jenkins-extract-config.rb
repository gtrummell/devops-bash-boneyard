#!/usr/bin/env ruby

# List all Jenkins objects, extract them to files, and create manifests

# Require gems
require 'jenkins_api_client'
require 'json'
require 'mixlib/cli'
require 'uri'
#require 'logger'

include FileUtils

# Initialize the logger
#@logger = Logger.new

include FileUtils

# Set up CLI inputs
class ExtractionCLI
  include Mixlib::CLI

  option :jenkins_url,
         :short => '-u URL',
         :long => '--url URL',
         :default => 'http://localhost',
         :description => 'The URL of the Jenkins Server',
         :required => true

  option :jenkins_port,
         :short => '-p PORT',
         :long => '--port PORT',
         :default => '8080',
         :description => 'The authorized port to connect to the Jenkins Server',
         :required => true

  option :jenkins_ssl,
         :short => '-s',
         :long => '--ssl',
         :default => false,
         :description => 'Enable Jenkins SSL (Default is false)',
         :boolean => true,
         :required => false

  option :jenkins_user,
         :short => '-n USERNAME',
         :long => '--username USERNAME',
         :description => 'The username to provide the Jenkins Server',
         :required => false

  option :jenkins_pass64,
         :short => '-w PASSWORD64',
         :long => '--password PASSWORD64',
         :description => 'The base64-encoded password for the Jenkins User. Use the base64 command on your *nix machine to hash your Jenkins password',
         :required => false

  option :export_path,
         :short => '-x PATH',
         :long => '--export_path PATH',
         :default => '~/tmp',
         :description => 'The path to which objects will be written',
         :required => false

  option :assign_ver,
         :short => '-v VERSION',
         :long => '--version VERSION',
         :default => '0.0.0',
         :description => 'The default version to assign objects that are not natively versioned',
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
extraction_cli = ExtractionCLI.new
extraction_cli.parse!

jenkins_url = extraction_cli.config[:jenkins_url]
jenkins_port = extraction_cli.config[:jenkins_port]
jenkins_ssl = extraction_cli.config[:jenkins_ssl]
jenkins_user = extraction_cli.config[:jenkins_user]
jenkins_pass64 = extraction_cli.config[:jenkins_pass64]
export_path = File.expand_path(extraction_cli.config[:export_path])
assign_ver = extraction_cli.config[:assign_ver]
verbose = extraction_cli.config[:verbose]

# Initialize the connection to the Jenkins Server
jenkins_client = JenkinsApi::Client.new(
    :server_url => jenkins_url,
    :server_port => jenkins_port,
    :ssl => jenkins_ssl,
    :username => jenkins_user,
    :password_base64 => jenkins_pass64
)

#
# Prep some manifest variables
#
jenkins_servername = URI.parse(jenkins_url).hostname.split('.').first
puts "Using Jenkins server #{jenkins_servername}"
puts "Using version #{assign_ver} for objects that are not natively versioned."

#
# Query the Jenkins server for lists of each object type.
#

# List all the plugins configured on this server
pluginlist = jenkins_client.plugin.list_installed.sort

puts 'Found the following plugins:' if verbose
pluginlist.each { |plugin, version| puts "#{plugin}, version #{version}" } if verbose

# List all the nodes attached to this server.
nodelist = jenkins_client.node.list.sort

puts 'Found the following nodes:' if verbose
nodelist.each { |node| puts node } if verbose

# List all the jobs configured on this server
joblist = jenkins_client.job.list_all.sort

puts 'Found the following jobs:' if verbose
joblist.each { |job| puts job } if verbose

# List all the views configured on this server
viewlist = jenkins_client.view.list.sort

puts 'Found the following views:' if verbose
viewlist.each { |view| puts view } if verbose

#
# Write out each object as a file into the export path
#

# Clear the export path
puts 'Clearing export path...' if verbose
FileUtils.rmtree(export_path)

# For each (plugin, node, job, view) do the following

# Create the export path root and object subpaths
puts 'Writing export paths...' if verbose
%w{ plugins nodes jobs views manifest }.each do |dir|
  dir_path = File.join(export_path, dir)
  if FileUtils.mkdir_p(dir_path)
    puts "Created path #{dir_path}" if verbose
  else
    raise "Failed to create #{dir_path}"
  end
end

# Set up a manifest file
manifest_file = File.open(File.join(export_path, 'manifest', "#{jenkins_servername}_manifest.json"), 'w')

manifest = Hash.new
manifest[:id] = jenkins_servername
manifest[:url] = jenkins_url
manifest[:date] = Time.now

# Export a manifest for plugins
plugin_hash = {}
pluginlist.each do |plugin, version|
  plugin_hash["#{plugin}"] = version
end
manifest[:plugins] = plugin_hash

# Export a configuration file for each node
nodelist.each do |node|
  nodeconfig = ''
  nodefile = File.open(File.join(export_path, 'nodes', "#{node}.xml"), 'w')
  puts "Opening #{nodefile} to write node config:" if verbose
  nodeconfig << jenkins_client.node.get_config(node)
  puts nodeconfig if verbose
  nodefile << nodeconfig
  nodefile.close
end
manifest[:nodes] = nodelist

# Export a configuration file for each job
joblist.each do |job|
  jobconfig = ''
  jobfile = File.open(File.join(export_path, 'jobs', "#{job}.xml"), 'w')
  puts "Opening #{jobfile} to write job config:" if verbose
  jobconfig << jenkins_client.job.get_config(job)
  puts jobconfig if verbose
  jobfile << jobconfig
  jobfile.close
end
manifest[:jobs] = joblist

# Export a configuration file for each view
viewlist.each do |view|
  viewconfig = ''
  viewfile = File.open(File.join(export_path, 'views', "#{view}.xml"), 'w')
  puts "Opening #{viewfile} to write view config:" if verbose
  viewconfig << jenkins_client.view.get_config(view)
  puts viewconfig if verbose
  viewfile << viewconfig
  viewfile.close
end
manifest[:views] = viewlist.sort

manifest_file << JSON.pretty_generate(manifest)
puts manifest_file if verbose
manifest_file.close

puts "Jenkins Configuration Extraction for #{jenkins_servername} complete"
