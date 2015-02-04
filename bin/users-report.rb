#!/usr/bin/env ruby

# ==Load gems
require 'chef/data_bag'

# ==Load Chef config

databag_path = File.expand_path(File.join(ARGV[0]), 'data_bags/users/*')

users = {}

Dir.glob(databag_path + '').sort.each do |file|
	bag = File.read(file)
	puts bag
end

puts users