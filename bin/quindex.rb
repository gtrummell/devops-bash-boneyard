#!/usr/bin/env ruby

require 'ini'
require 'git'

index_file = File.expand_path('/opt/splunk/etc/master-apps/indexes_stackwatchr/local/indexes.conf')
indexes_conf = Ini.new(index_file, options = { :comment => '#' })

stax_dir = File.expand_path('~/tmp/stax')
stax_git = Git.clone('git@github.com:SplunkStorm/stax', stax_dir)

stax_git.checkout('master')
stax_git.pull

stax_db = []
Dir.glob("#{stax_dir}/*.json").each do |file|
  stax_db << File.basename(file).gsub('.json', '')
end

puts stax_db

puts indexes_conf