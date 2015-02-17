#!/usr/bin/env ruby

# required_gems = %W{chef git logger mixlib/cli}
#
# required_gems.each do |required_gem|
#   begin
#     gem required_gem.gsub(/\//, '-')
#   rescue
#     begin
#       system("gem install #{required_gem}")
#       Gem.clear_paths
#     rescue
#       raise("Unreachable, or incorrect permission to install #{required_gem}")
#     end
#   end
#
#   require required_gem
# end

require 'chef'
require 'git'
require 'logger'
require 'mixlib/cli'
require 'foodcritic'

class ReleaseEnvCLI
  include Mixlib::CLI

  option :environment,
         :short => '-e ENVIRONMENT',
         :long  => '--env ENVIRONMENT',
         :default => 'development',
         :required => true,
         :description => 'Chef Environment being released'

  option :cookbook,
         :short => '-b { :COOKBOOK => SEMVER[, ...] } | file',
         :long  => '--cookbooks COOKBOOK',
         :default => 5,
         :required => true,
         :description => 'Hash of cookbooks and semantic versions to release'

  option :chefconfig,
         :short => '-c CONFIG-FILE',
         :long => '--config-file CONFIG-FILE',
         :default => '',
         :required => false,
         :description => 'Alternate location of the Chef config file'

  option :help,
         :short => '-h',
         :long => '--help',
         :description => "Display help for #{File.basename(__FILE__).gsub(/\..*/, '')}",
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0
end


# Set up the logger
class ReleaseEnvLogger
  def initialize(level, msg)
    level = level || 'warn'
    msg = msg || ''

    log_levels = %w{debug info warn error fatal}

    log_entry = Logger.new(STDERR)
    log_entry.progname = File.basename(__FILE__).gsub(/\..*/, '')
    log_entry.datetime_format = '%Y-%M-%d %H:%M:%S'
    if log_levels.include?(level)
      log_entry.send(level) {"#{msg}"}
    else
      log_entry.unknown('unknown') {"#{msg}"}
    end
  end
end

# Set up the Repo class
class ReleaseEnvRepo
  def initialize(remote_path, local_path)
    puts remote_path
    puts local_path
  end

  def sync
    puts 'Sync'
  end

  def clear
    puts 'Delete the local repo'
  end

  def checkout_branch(branch)
    puts('Check out ' + branch.to_s)
  end

  def clone(repo)
    puts('Cloning ' + repo.to_s)
  end
end


# Set up the EnvObject class
class ReleaseEnvParser
  def initialize(env, update)
    @env = env
    @update = update
  end

  def parse(env)
    if File.exist?(env)
      env_data = File.open(File.expand_path(env))
    else
      env_data = env
    end
    JSON.parse(env_data)
  end

  def update
    previous_env = self.parse(@env)
    update_env = self.parse(@update)
    previous_env.merge(update_env)
  end

  def write
    self.update
    File.write(@env)
  end

  def chef_test
    subject_env = self.parse(@env)
    puts("Someday I'll test " + subject_env.to_s)
  end
end


release_cli = ReleaseEnvCLI.new
release_cli.parse_options

