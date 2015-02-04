#!/usr/bin/env ruby

# Check the Nagios JSON interface provided by nagios-api (TODO: Add link and doc)
# This is pattern for querying the Nagios server

require 'chef/search/query'
require 'mixlib/cli'
require 'net/https'
require 'json'
require 'logger'

# == CLI - Set up an options parser
class ChronosCheckCli
  include Mixlib::CLI

  option :env,
         :boolean => false,
         :default => 'local',
         :description => 'Chef environment queried for Chronos nodes',
         :long  => '--env ENVIRONMENT',
         :short => '-e ENVIRONMENT'

  option :config,
         :boolean => false,
         :default => %w(~/.chef/knife.rb ~/.chef/client.rb /etc/chef/knife.rb /etc/chef/knife.rb),
         :description => 'Path to Chef configuration file',
         :long  => '--config CONFIG',
         :short => '-f CONFIG'

  option :proto,
         :boolean => false,
         :default => 'http',
         :description => 'Specify the protocol to contact the Chronos server (defaults to http)',
         :long  => '--proto PROTO',
         :short => '-p PROTO'

  option :state_file,
         :boolean => false,
         :default => '/dev/shm/chronos-state.json',
         :description => 'Path to the state file',
         :long  => '--state-file STATE-FILE',
         :short => '-s STATE-FILE'

  option :state_file_age,
         :boolean => false,
         :default => 3,
         :description => 'Amount of time to allow before refreshing the state file',
         :long  => '--state-age TIME',
         :short => '-t TIME'

  option :verbose,
         :boolean => true,
         :default => false,
         :description => 'Turn on verbose logging',
         :long  => '--verbose',
         :required => true,
         :short => '-v'

  option :help,
         :boolean => true,
         :default => false,
         :description => 'Show this help message',
         :exit => 0,
         :long => '--help',
         :on => :tail,
         :short => '-h',
         :show_options => true
end

# == ChronosCheck - a class to find a Chronos node and query it for task status.
class ChronosCheck

	# === Initialize Class
	# For now feed in the port and protocol.
	def initialize(*args)	# ChronosCheck.new(chef_environment, chef_config, chronos_protocol, state_file, state_file_age, )
		@chef_environment = args[0]||'local'

    args[1] = args[1].split(/, /) if args[1].class == 'String'
    @chef_configs = args[1]||%w(~/.chef/knife.rb ~/.chef/client.rb /etc/chef/knife.rb /etc/chef/knife.rb)
		@chronos_proto = args[2]||'http'
		@state_file = args[3]||File.expand_path('/dev/shm/chronos-state.json')
		@state_file_age = args[4]||3
	end

  # === Configure Chef Objects for Class
	# Configure Chef
	def chef_config
#		begin
			# Configure Chef for this instance of the class.
			@chef_configs.each do |config|
        next unless Chef::Config.from_file(File.expand_path(config))
			end
#		rescue
#			raise("Chef config error, tried: #{@chef_configs.join(', ')}")
#		end
	end

	# Search Chef for nodes that are running the Chronos recipe in the designated
	# environment.  The first object returned in the array contains server objects.
	def get_chronos_host
		chef_config
		chef_query = Chef::Search::Query.new
		chronos_host = chef_query.search('node', "recipes:*chronos* AND chef_environment:#{@chef_environment}")[0].sample.name
		# noinspection RubyResolve
		chronos_node = Chef::Node.load(chronos_host)

		@domain = chronos_node['domain']
		@chronos_base_url = "#{@chronos_proto}://#{chronos_node['fqdn']}:#{chronos_node['chronos']['http_port']}"
	end

	# === Use Net::HTTP to communicate with the Chronos API
	# Get status on all tasks and place into the state file for efficiency
	def refresh_state
		# Get an available Chronos host
		get_chronos_host
		chronos_url = URI.parse("#{@chronos_base_url}/scheduler/jobs")

		# TODO: Find out if the state file needs to be written
		# if File.exists?(@state_file)
		# 	chronos_state = JSON.parse(File.read(@state_file))
		# 	if URI.parse(chronos_state['chronos_url']) == chronos_url
		# 		next
		# 	end
		# else
		# end

		# Get task data from the Chronos API
		chronos_response = JSON.parse(Net::HTTP.get(chronos_url)).sort_by { |task| task['name'] }
		state_data = {
				:chronos_url => chronos_url,
				:query_time => DateTime.now,
				:tasks => chronos_response
		}
    @state_data = state_data

    # Write to the State file
    File.open(@state_file, 'w') do |file|
      file.write(JSON.pretty_generate(@state_data))
    end
  end

  # Read from the state file
  def parse_tasks
		refresh_state
		chronos_tasks = JSON.parse(File.read(@state_file))
		nagios_data = []
		chronos_tasks['tasks'].each do |task|
			# Output a Nagios OK for a task with a last success
			if task['errorSinceLastSuccess'].to_i == 0 &&
					task['lastSuccess'].to_s != ''
				status = 0
				output = "#{task['name']} OK: No errors since last success at #{task['lastSuccess']}"

			# Issue a warning if the task is disabled.
			elsif task['disabled'].to_s == 'true'
				status = 1
				output = "#{task['name']} WARNING: Task disabled!"

			# Output a Nagios CRITICAL for enabled tasks with no successes
			elsif task['lastSuccess'].to_s == '' && task['lastError'] != ''
				status = 2
				output = "#{task['name']} CRITICAL: Task cannot run! No successful runs recorded! Last error at #{task['lastError']}"

			# Output a Nagios CRITICAL for tasks that have succeeded, but are now failing (i.e., a new failure).
			elsif	task['lastError'].to_s != '' &&
					task['errorSinceLastSuccess'].to_i > 1 &&
					task['lastSuccess'].to_s != ''
				status = 2
				output = "#{task['name']} CRITICAL: Task is now failing since last success at #{task['lastSuccess']}"

			# Output a Nagios CRITICAL for tasks that are enabled, but have never run.
			elsif	task['lastSuccess'].to_s == '' &&
					task['lastError'].to_s == ''
				status = 2
				output = "#{task['name']} CRITICAL: Task cannot run! No successes or errors recorded!"

			# If none of these tests match, then we are in an unknown state
			else
				status = 3
				output = "#{task['name']} UNKNOWN: No conditions match known task state!"
			end

			# Return a hash in preparation for sending a REST call to Nagios
			nagios_data << {
				:host => "chronos.#{@domain}",
				:service => task['name'],
				:status => status,
				:output => output#,
			}

			# Some task items for future use, i.e, are we in schedule?
			# task['epsilon']
			# task['retries']
			# task['disabled']
			# task['softError']
			# task['lastError'] unless task['lastError'].nil?
			# task['lastSuccess']
			# task['schedule']
			# task['parents']
    end

    # output the parsed tasks.
		nagios_data
  end

  def post_nagios
    # TODO: Submit this information to Nagios
    # Return the hash for now
  end

  def return
end

# Do some script-ey stuff now.

cli_data = ChronosCheckCli.new
cli_data.parse_options

puts ARGV[0]

my_check = ChronosCheck.new(cli_data.config[:env], cli_data.config[:config], cli_data.config[:proto], cli_data.config[:state_file], cli_data.config[:state_file_age])

checks = JSON.pretty_generate(my_check.parse_tasks)
puts checks if cli_data.config[:verbose]
