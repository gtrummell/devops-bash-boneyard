#!/usr/bin/env ruby -w

require 'json'

# All groups loaded from file
all_groups = JSON.parse(File.read('../etc/os_groups.json'))


### This stuff goes in the recipe

# Set a default security environment in attributes.  This can be overridden in the PO
env = all_groups['whisper_base']['sudo']['security_env']['default']
puts "Using environment: #{env}"

# Expand the groups listed in the security environment.  Each environment is a list of Linux groups.
# These are the groups that will be populated on the system.
env_groups = all_groups['whisper_base']['sudo']['security_env']['environments'][env]
puts "Groups in environment #{env}: #{env_groups}"

# Simulation of what happens in the recipe
env_groups.each do |env_group|
  all_groups['whisper_base']['sudo']['groups'].each do |group|
    puts group if group['name'] == env_group
  end
end
