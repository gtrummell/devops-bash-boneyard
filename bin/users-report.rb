#!/usr/bin/env ruby

databag_path = File.expand_path('~gtrummell/Source/narwin/config/chef/data_bags/users')

users = {}

Dir.glob(databag_path + '/*').sort.each do |file|
	bag = File.read(file)
	puts bag
end

puts users