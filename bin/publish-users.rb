#!/usr/bin/env ruby

# Author:: Splunk Development Operations <splunk-whisper-accounts@splunk.com>
#
# Copyright 2012-2013, Splunk, Inc
#  created 14-oct-2013 by Graham Trummell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by aputslicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Require gems
require "chef/config"
require "chef/data_bag_item"
require "mixlib/cli"
require "rubygems"
require "json"


# Set up CLI inputs
class CLI
  include Mixlib::CLI

  # Check for and if necessary set the current workspace
  if ENV["WORKSPACE"].nil?
    workspace = File.join(".")
  elsif File.directory?(ENV["WORKSPACE"])
    workspace = ENV["WORKSPACE"]
  end

  option :data_bag,
         :short => "-d PATH",
         :long => "--data-bag PATH",
         :description => "Filename or Directory path to the data bag(s) to update",
         :default => File.join(workspace, "config", "chef", "data_bags", "users"),
         :required => false

  option :knife_config,
         :short => "-c PATH",
         :long => "--knife-config PATH",
         :description => "Knife configuration file",
         :default => File.join(workspace, "tools", "jenkins", "chefconfig", "knife.rb"),
         :required => true

  option :verbose,
         :short => "-v",
         :long => "--verbose",
         :description => "Run verbosely",
         :boolean => true,
         :required => false

  option :help,
         :short => "-h",
         :long => "--help",
         :description => "Show this message",
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :required => false,
         :exit => 1

  def parse!(argv = ARGV)
    parse_options(argv)
  end
end


# Parse command-line options
cli = CLI.new
cli.parse_options
data_bag = cli.config[:data_bag]
knife_config = cli.config[:knife_config]
verbose = cli.config[:verbose]


# Read in the knife configuration from file. Quit if we can"t find one.
raise("No knife configuration specified!") if knife_config.nil?
puts("Using knife configuration file at #{knife_config}") if verbose
Chef::Config.from_file(knife_config)


# Test the data bag path to make sure it is file or directory. Quit if it"s not a valid path.
# Quit if we don"t get a data bag path.
raise("No data bag path specified.") if data_bag.nil?
puts("Using data bag path #{data_bag}") if verbose

if File.directory?(data_bag)
  upload_list = Dir.glob("#{data_bag}/*.json")
elsif File.file?(data_bag)
  upload_list = []
  upload_list << data_bag
else
  raise("Data bag path is not an existing file or directory.")
end

if verbose
  puts("Using data bags from files:")
  upload_list.each do |item|
    puts item
  end
end


# Make sure the users data bag exists
#noinspection RubyResolve
if Chef::DataBag.load("users")
  puts("Users data bag exists") if verbose
else
  puts("Creating users data bag") if verbose
  users_data_bag = Chef::DataBag.new
  users_data_bag.name("users")
  users_data_bag.create
end


# Test and upload the named data bag or each file in the directory of databags.
# Ignore the file if it fails a JSON parse test.
upload_list.each do |item|
  if JSON.parse(IO.read(item))
    puts("Validated JSON and uploading data bag #{item}") if verbose
    data_bag_item = Chef::DataBagItem.new
    data_bag_item.data_bag("auth")
    data_bag_item.raw_data = JSON.parse(IO.read(item))
    data_bag_item.save
  else
    puts("Data bag item JSON validation on #{item}")
  end
end