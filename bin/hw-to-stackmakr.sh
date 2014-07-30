#!/bin/bash

require "mixlib/cli"
require "git"
require "json"
require "find"

class CLI
  include Mixlib::CLI

  option :repo,
         :short => "-r REPOSITORY",
         :long => "--repo REPOSITORY",
         :description => "Repository from which to checkout users",
         :required => "true"

  option :data_bags,
         :short => "-d DATABAGPATH",
         :long => "--databags DATABAGPATH",
         :description => "Path to checkout repository and locate data bags.",
         :required => "false",
         :default => "#{ENV['WORKSPACE']}/narwin/config/chef/data_bags/users/"

  option :etc_passwd,
         :short => "-p PATH",
         :long => "--passwd PATH",
         :description => "Path to /etc/passwd, or passwd-formatted file",
         :required => "false",
         :default => "/etc/passwd"

  option :etc_group,
         :short => "-g PATH",
         :long => "--group PATH",
         :description => "Path to /etc/group, or a group-formatted file",
         :required => "false",
         :default => "/etc/group"

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

# Assign CLI variables
cli = CLI.new
cli.parse_options
repo = cli.config[:repo]
databag_dir = File.expand_path(cli.config[:data_bags])
etc_passwd_file = File.expand_path(cli.config[:etc_passwd])
etc_group_file = File.expand_path(cli.config[:etc_group])
verbose = cli.config[:verbose]

# Analyze repository path
repo_name = repo.split("/", 2).last.gsub(".git", "")
repo_seg = File.expand_path(databag_dir).split(repo_name)
repo_home = File.join(repo_seg.first, repo_name)

# Get the narwin repo.  Git must be preconfigured, we don't handle credentials yet.
# SHORTCUT - Commenting below
puts("Work tree does not exist #{repo_home}") if verbose unless FileUtils.rmtree(repo_home)
puts("Creating work tree #{repo_home}...") if verbose
FileUtils.mkdir_p(repo_home)
puts("Cloning #{repo_name} repository from #{repo} to #{repo_home}...")
raise("Failed to clone repo") if verbose unless (users_repo = Git.clone(repo, repo_name, {path: repo_home, bare: false}))
puts("Checking out develop branch of #{users_repo}...") if verbose
raise("Failed to checkout repo") if verbose unless users_repo.checkout("develop")
puts("Performing git pull...") if verbose
raise("Failed to pull repo") unless users_repo.pull(remote: repo, branch: "develop")

# Read the users from data bags
data_bags = Dir.glob("#{databag_dir}*.json").map { |file| JSON.parse(File.read(file)) }

# Verbose diagnostics for data bag users
puts("==> Parsing data bags...") if verbose
data_bags.each do |bag|
  puts("User #{bag["id"]} (#{bag["comment"]}) with uid #{bag["uid"]} home directory #{bag["home"]} and shell #{bag["shell"]}, in groups:") if verbose
  bag["groups"].each do |group|
    puts group if verbose
  end
end

# Read the users from /etc/passwd
etc_passwd = []
File.read(etc_passwd_file).each_line do |line|
  if line.slice(0) == "#"
    next
  else
    line_array = line.split(":")
    etc_passwd << { id: line_array[0], uid: line_array[2].to_i }
  end
end

# Verbose diagnostics for /etc/passwd
puts("==> Parsing #{etc_passwd_file}...") if verbose
etc_passwd.each do |user|
  puts("User #{user[:id]} with uid #{user[:uid]}") if verbose
end

# Read in groups from /etc/group
etc_group = []
File.read(etc_group_file).each_line do |line|
  if line.slice(0) == "#"
    next
  else
    line_array = line.split(":")
    etc_group << { group_name: line_array[0], gid: line_array[2].to_i }
  end
end

# Verbose diagnostics for /etc/group
puts("==> Parsing #{etc_group_file}...") if verbose
etc_group.each do |group|
  puts("Group #{group[:group_name]} with gid #{group[:gid]}") if verbose
end

# Get a list of files on the filesystem
target_files = []
Dir.glob("/Users/**/*").each do |entry|
  target_files << { filename: entry, uid: File.stat(entry).uid, gid: File.stat(entry).gid }
end
pp target_files

# Compare data bag and passwd users. Add users who have mismatched uid/gid to the list
puts("==> Comparing data bags and #{etc_passwd_file}...") if verbose
data_bags.each do |bag|
  passwd_user = etc_passwd.find { |passwd| passwd[:id] == bag["id"] && (passwd[:uid].to_i != bag["uid"].to_i or passwd[:gid] != bag["gid"]) }
  next if passwd_user.nil?
  puts("#{bag["id"]} is a mismatch. Aligning with #{repo_name}") if verbose
end
