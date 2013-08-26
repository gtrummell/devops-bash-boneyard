#!/usr/bin/env ruby

#
# A quick script to query Chef for metrics.
#

# Gems
require 'chef'
require 'json'

# Figure out where the Chef or Knife config file is
chef_config_homes = ['/etc/chef/client.rb', '/etc/chef/knife.rb', File.join(ENV['HOME'], '.chef', 'knife.rb')]
chef_config_homes.each do |home|
  puts("Testing #{home}")
  puts("File does not exist: #{home}") && next unless File.exist?(File.expand_path(home))
  puts("Found #{home}")
  @chef_config = home
end

# Load the Chef configuration file
Chef::Config.from_file(@chef_config)

# Extract configuration values for the CHEF rest client
chef_server_url = Chef::Config[:chef_server_url]

# Load the Chef REST client
chef_rest = Chef::REST.new(chef_server_url)

nodes = chef_rest.get_rest('/nodes/')
environments = chef_rest.get_rest('/environments/')

nodes.keys.each do |node_name|
  node = chef_rest.get_rest("/nodes/#{node_name}/")
  puts node.to_json
end

environments.keys.each do |env_name|
  env = chef_rest.get_rest("/environments/#{env_name}")
  puts env.to_json
end
