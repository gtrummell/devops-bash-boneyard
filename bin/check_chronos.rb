#!/usr/bin/env ruby

# Check the Nagios JSON interface provided by nagios-api (TODO: Add link and doc)
# This is pattern for querying the Nagios server

require 'chef/search/query'
require 'net/https'
require 'json'

# == Set up the CLI - stubbed for now!
# We just need defaults

# == Use Chef to find a Chronos node
class ChronosCheck

	# === Initialize
	# For now feed in the port and protocol.
	def initialize(*args)	# ChronosCheck.new(chef_environment, chronos_protocol, state_file, state_file_age, chef_config)
		@chef_environment = args[0]||'production'
		@chronos_proto = args[1]||'http'
		@state_file = args[2]||File.expand_path('/tmp/chronos-' + @chef_environment + '-state.json')
		@state_file_age = args[3]||3
		@chef_configs = args[4]||%w(~/.chef/knife.rb ~/.chef/client.rb /etc/chef/knife.rb /etc/chef/knife.rb)

	end

	# Configure Chef
	def chef_config
		begin
			# Configure Chef for this instance of the class.
			@chef_configs.each do |config|
				next unless Chef::Config.from_file(File.expand_path(config))
			end
		rescue
			raise("Chef config error, tried: #{@chef_configs}")
		end
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
	def get_tasks
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

		# Write to the State file
		File.open(@state_file, 'w') do |file|
			file.write(JSON.pretty_generate(state_data))
		end
	end

	def task_check_exec
		get_tasks
		chronos_tasks = JSON.parse(File.read(@state_file))
		chronos_2_nagios = []
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

			# If none of these tests match, then we are in an unkown state
			else
				status = 3
				output = "#{task['name']} UNKNOWN: No conditions match known task state!"
			end

			# Return a hash in preparation for sending a REST call to Nagios
			chronos_2_nagios << {
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
		# TODO: Submit this information to Nagios
		# Return the hash for now
		chronos_2_nagios
	end
end

my_check = ChronosCheck.new
checks = JSON.pretty_generate(my_check.task_check_exec)

puts checks