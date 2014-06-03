#!/usr/bin/env ruby

# Jenkins Plugin Cleanup
#
# This program is licensed under the terms of the GNU General Public License v3
# https://www.gnu.org/copyleft/gpl.html
#
# Possession or use of this code in any way constitutes agreement with the terms of the aforementioned license
# agreement.
#
# A script to check your jobs to find out which plugins are needed, and tells you which plugins are default for the
# version of jenkins you have installed as indicated in config.xml.  Optionally, this script can remove extraneous
# plugins automatically.

# Required Gems
require 'mixlib/cli'
require 'nokogiri'
require 'json'

# Set up CLI inputs
class CLI
  include Mixlib::CLI

  option :jenkins_dir,
         :short => '-j JENKINS_DIR',
         :long => '--jenkins-dir JENKINS_DIR',
         :description => 'Path to Jenkins main config.xml and Jobs',
         :default => File.join('', 'var', 'lib', 'jenkins'),
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


# Parse CLI options
# Parse command-line options
cli = CLI.new
cli.parse_options
jenkins_dir = cli.config[:jenkins_dir]
verbose = cli.config[:verbose]


# Load and parse the Jenkins config file and search it for version information
# Notify user of load success if verbose
jenkins_config_file = File.expand_path(File.join(jenkins_dir, 'config.xml'))

jenkins_config_xml = Nokogiri::XML(File.open(jenkins_config_file)) or
    raise('Failed to load Jenkins configuration file ')

puts("Loaded Jenkins configuration file #{jenkins_config_file}\n") if verbose

# Get the version of Jenkins that last modified this config file
jenkins_version = jenkins_config_xml.xpath('//version').text

puts("This Jenkins configuration was last modified by version #{jenkins_version}") if verbose


# Get a list of XML files.  We want only develop-able objects, which means we are looking for main configurations,
# such as extensions or capabilities, as well as jobs and views.
#
# First crawl the Jenkins home directory for XML files
jenkins_xml_files = Dir.glob(File.join(jenkins_dir, '*.xml')) or
    raise("Failed to find xml files in #{jenkins_dir}")

# Now crawl the Jenkins jobs directory
jenkins_xml_files << Dir.glob(File.join(jenkins_dir, 'jobs', '**', 'config.xml')) or
    raise("Failed to find xml files in #{jenkins_dir}/jobs")

# Flatten the array
jenkins_xml_files.flatten!.sort!


# Get a list of plugins called by each object.  Ensure the list is unique, and put the data into a hash of objects.
# Set up the plugin report hash, and add some basic info
plugin_report = Hash.new
plugin_report['name'] = 'Plugin cleanup report'
plugin_report['date'] = Time.now
plugin_report['jenkins_version'] = jenkins_version

# Report on plugins called by each file
object_hash = Hash.new
jenkins_xml_files.each do |file|
  # Report object name
  object = file.split('/')[-2]

  # Break the file into lines, grabbing only lines that contain plugin syntax.  Make sure lines are unique, skip to the
  # next file if the line array is empty.
  lines = []
  File.open(file).each_line do |line|
    lines << line.to_s.split('plugin="', 2)[1].gsub(/".*\n/, '') if line.match(/plugin=.*@/)
  end
  next if lines.empty?
  lines.uniq!

  # Add each line into a plugin-version hash with the object name as a key
  plugin_hash = Hash.new
  lines.each do |line|
    plugin_data = line.split('@')
    plugin_hash["#{plugin_data[0]}"] = "#{plugin_data[1]}"
  end

  # Add the hash of plugins into the hash for the object
  object_hash["#{object}"] = plugin_hash

end

# Add the object hash to the plugin report
plugin_report['objects'] = object_hash

# Create a master list of unique plugins based on what's already been found
plugin_master = Hash.new
plugin_report['objects'].values.each do |values|
  values.each do |plugin, version|
    plugin_master["#{plugin}"] = "#{version}"
  end
end

# Add the master list to the report under its own key
plugin_report['plugins'] = plugin_master

#puts "\nThis is the complete hash:"
puts JSON.pretty_generate(plugin_report)
