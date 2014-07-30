#!/usr/bin/env ruby

#
# A quick script to query Chef for metrics.
#

# Gems
require "chef"
require "json"

# Figure out where the Chef or Knife config file is
if File.exist?(File.expand_path("/etc/chef/client.rb"))
  chef_config = File.expand_path("/etc/chef/client.rb")
elsif File.exist?(File.expand_path("/etc/chef/knife.rb"))
  chef_config = File.expand_path("/etc/chef/knife.rb")
elsif File.exist?(File.join(ENV['HOME'], ".chef", "knife.rb"))
  chef_config = File.join(ENV['HOME'], ".chef", "knife.rb")
else
  raise("No knife configuration file found")
end

# Load the Chef configuration file
Chef::Config.from_file(chef_config)

# Extract configuration values for the CHEF rest client
chef_server_url = Chef::Config[:chef_server_url]
chef_client_name = Chef::Config[:node_name]
signing_key_filename = Chef::Config[:client_key]

# Load the Chef REST client
chef_rest = Chef::REST.new(chef_server_url, chef_client_name, signing_key_filename)

nodes = chef_rest.get_rest("/nodes/")
environments = chef_rest.get_rest("/environments/")

nodes.keys.each do |node_name|
  node = chef_rest.get_rest("/nodes/#{node_name}/")
  puts node.to_json
end

environments.keys.each do |env_name|
  env = chef_rest.get_rest("/environments/#{env_name}")
  puts env.to_json
end