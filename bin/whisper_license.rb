#!/usr/bin/env ruby
require 'chef'

Chef::Config.from_file(File.expand_path('~/.chef/knife.rb'))

require_relative '../lib/splunk/rest/license'

#
# Script-ey bits!
#

# Initialize
splunk_license = License.new(
    '',
    options = {
        :file => '/srv/chef/file_store/splunk.license',
        :hostname => 'lm1.gtrummell.splunkcloud.com',
        :port => 8089,
        :use_https => true,
        :username => '',
        :password => '',
        :verbose => true
    }
)

# See if a delete works
#puts splunk_license.delete

puts splunk_license.cli_add

# Print out the results of a GET operation.
puts splunk_license.verify

# Print out the resuls of a POST operation.
puts splunk_license.create

# Verify again
puts splunk_license.verify