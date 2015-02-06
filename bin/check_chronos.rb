#!/usr/bin/env ruby

# Check the Nagios JSON interface provided by nagios-api (TODO: Add link and doc)
# This is pattern for querying the Nagios server

require 'chef/search/query'
require 'date'
require 'json'
require 'logger'
require 'mixlib/cli'
require 'net/https'

# == CLI - Set up an options parser
class ChronosCheckCli
  include Mixlib::CLI

  option :env,
         :boolean => false,
         :default => '_default',
         :description => 'Chef environment queried for Chronos nodes',
         :long  => '--env ENVIRONMENT',
         :short => '-e ENVIRONMENT'

  option :config,
         :boolean => false,
         :default => %w(~/.chef/knife.rb ~/.chef/client.rb /etc/chef/knife.rb /etc/chef/client.rb),
         :description => 'Path to Chef configuration file',
         :long  => '--config PATH',
         :required => false,
         :short => '-c PATH'

  option :nagios_check,
         :boolean => false,
         :default => 'test-echo',
         :description => 'Run a Nagios check against Chronos Task <TASK>',
         :long => '--task TASK',
         :required => false,
         :short => '-t TASK'

  option :proto,
         :boolean => true,
         :default => false,
         :description => 'Specify HTTPS to contact the Chronos server (defaults to HTTP)',
         :long  => '--https',
         :required => false

  option :state_file,
         :boolean => false,
         :default => '/tmp/chronos-state.json',
         :description => 'Path to the state file',
         :long  => '--state-file PATH',
         :required => false

  option :state_file_age,
         :boolean => false,
         :default => 3,
         :description => 'Amount of time to allow before timing out and refreshing the state file',
         :long  => '--state-timeout MINUTES',
         :required => false

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
	def initialize(*args)	# ChronosCheck.new(chef_environment, chef_config, chronos_protocol, state_file, state_file_age)
    @chef_environment = "#{args[0]}"||'_default'

    args[1] = args[1].split(/, /) if args[1].class == 'String'
    @chef_configs = args[1]||%w(~/.chef/knife.rb ~/.chef/client.rb /etc/chef/knife.rb /etc/chef/client.rb)

    @chronos_proto = args[2]||'http'
		@state_file = File.expand_path(args[3])||'/tmp/chronos-state.json'
		@state_file_age = args[4]||3
    @logger = Logger.new(STDOUT)
	end

  # === Configure Chronos Server using Chef
  def get_chef_node
    # Set up logging

    # If our target environment doesn't exist, fail gracefully.
    available_environments = Chef::Environment.list.keys
    raise @logger.fatal("Environment does not exist on Chef server! #{@chef_environment}") unless
        available_environments.include?(@chef_environment)

    # Configure Chef for this instance of the class.
    @chef_configs.each do |config|
      if ! File.exist?(config)
        next
      elsif ! Chef::Config.from_file(File.expand_path(config))
        next
      else
        raise @logger.fatal("Could not load configuration from: #{@chef_configs.join(', ')}")
      end
    end

    # Search Chef for nodes that are running the Chronos recipe in the selected
    # @chef_environment.  Pick a server at random from the list.
    chef_query = Chef::Search::Query.new
    raise @logger.fatal("Could not find a Cronos node in #{@chef_environment}") unless
        ( chronos_node_name =
            chef_query.search('node', "recipes:*chronos* AND chef_environment:#{@chef_environment}")[0]
                .sample.name )

    # Load the Chronos server's Chef node data
    # noinspection RubyResolve
    raise @logger.fatal("Could not load node data for #{chronos_node_name}") unless
        ( chronos_node = Chef::Node.load(chronos_node_name.to_s) )

    # Set the Chronos server's base URL.
    @chronos_base_url = "#{@chronos_proto}://#{chronos_node['fqdn']}:#{chronos_node['chronos']['http_port']}"

    # Return the Node object as the output of the method.
    chronos_node
  end

  # === Get State from the Chronos Server
  def refresh_state
    self.get_chef_node
    begin
      chronos_url = URI.parse("#{@chronos_base_url}/scheduler/jobs")

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
    rescue
      raise @logger.fatal("Could not generate state data in file #{@state_file} from #{chronos_url}")
    end
  end

  # === Check for state freshness and update if necessary
  def state_timer
    # Set the time the state file expires, based on @state_file_age
    state_file_expires_on = DateTime.now - Rational(@state_file_age.to_i, 1440)

    # If the state file doesn't exist, refresh state data and write state file
    if ! File.exist?(@state_file)
      self.refresh_state

    # Else if the state file exists, test its validity
    elsif File.exist?(@state_file)
      # Get the state file's timestamp.
      state_file_timestamp = DateTime.parse(JSON.parse(File.read(@state_file))['query_time'])

      # TODO: If the file timestamp and doesn't match the modify time, assume tampering and refresh state data.

      # Refresh state unless the state file's timestamp shows that it hasn't yet expired.
      self.refresh_state unless state_file_timestamp < state_file_expires_on
    else
      false
    end
  end

  # === Parse tasks from the state file.
  def parse_tasks
    # Refresh state if needed, set up variables.
    self.state_timer
		chronos_tasks = JSON.parse(File.read(@state_file))
    chronos_domain = URI.parse(chronos_tasks['chronos_url']).host.split('.').drop(1).join('.')

		# Prepare state information for Nagios checks
    task_data = []
    chronos_tasks['tasks'].each do |task|

      # Parse the success and error times if any have been recorded.
      #(task['epsilon'] == '') ?
      #    epsilon = nil :
      #    epsilon = Date.parse(task['epsilon'])

      (task['lastError'] == '') ?
          last_error = nil :
          last_error = DateTime.parse(task['lastError'])

      (task['lastSuccess'] == '') ?
          last_success = nil :
          last_success = DateTime.parse(task['lastSuccess'])

      # Output a Nagios WARNING if the task is disabled.
      if task['disabled']
        status = 1
        output = "#{task['name']} WARNING: Task disabled!"

			# Output a Nagios CRITICAL for enabled tasks with no successes or failure
			elsif ! last_error && ! last_success
				status = 2
				output = "#{task['name']} CRITICAL: Task cannot run! No successful or failed runs."

      # Output a Nagios CRITICAL for tasks that are failing with no successes
      elsif last_error && ! last_success
        status = 2
        output = "#{task['name']} CRITICAL: Task cannot run! No successes, recorded last failure at #{last_error}"

      # Output a Nagios OK for tasks that have succeeded with no failures. TODO: Make sure this is within epsilon
      elsif last_success && ! last_error
        status = 0
        output = "#{task['name']} OK: Task no failures detected, last success recorded at #{last_success}"

      # Output a Nagios OK for tasks with current success status
      elsif last_success > last_error
        status = 0
        output = "#{task['name']} OK: Task success recorded at #{last_success}"

      # Output a Nagios CRITICAL for tasks with a current failing status. TODO: Make sure this is within epsilon
      elsif last_error > last_success
        status = 2
        output = "#{task['name']} CRITICAL: Task failed! Error recorded at #{last_success}"

      # TODO: Output a Nagios CRITICAL for tasks that fail to meet their epsilon
      #elsif epsilon > ( last_success + epsilon )
      #  status = 2
      #  output = "#{task['name']} CRITICAL: Task did not run within its epsilon! Last run at #{last_success}"

			# If none of these tests match, then we are in an unknown state
			else
				status = 3
				output = "#{task['name']} UNKNOWN: No conditions match known task state!"

      end

			# Return a hash in preparation for sending a REST call to Nagios
			task_data << {
				:host => "chronos.#{chronos_domain}",
				:service => task['name'],
				:status => status,
				:output => output#,
			}
    end
    task_data
  end

  # === TODO: Write out the Nagios commands definition and chronos host.
  def write_nagios_config
    task_list  = self.parse_tasks
    task_list.each do |task|
      puts JSON.pretty_generate(task)
    end
  end

  # === TODO: Post Chronos task data to Nagios via nagios-api
  def post_nagios
    JSON.pretty_generate(self.parse_tasks)
  end

  # === Submit a check for an individual Chronos task.
  def post_nrpe(task_name)
    nrpe_task = self.parse_tasks.select { |task| task[:service] == task_name }.first
    puts nrpe_task[:output]
    exit(status=nrpe_task[:status].to_i)
  end
end

# == Do some work now!

# === Parse the CLI
cli_data = ChronosCheckCli.new
cli_data.parse_options

cli_state_file = File.expand_path(cli_data.config[:state_file])
cli_state_file_age = cli_data.config[:state_file_age].to_i
if cli_data.config[:proto]
  cli_proto = 'https'
else
  cli_proto = 'http'
end


# === Execute the checks requested by the user.
my_check = ChronosCheck.new(cli_data.config[:env], cli_data.config[:config], cli_proto, cli_state_file, cli_state_file_age)

my_check.post_nrpe(cli_data.config[:nagios_check])
