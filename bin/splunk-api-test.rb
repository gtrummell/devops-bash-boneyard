#!/usr/bin/env ruby

required_gems = %W{rest-client logger mixlib/cli}

required_gems.each do |required_gem|
  begin
    gem required_gem.gsub(/\//, '-')
  rescue
    begin
      system("gem install #{required_gem}")
      Gem.clear_paths
    rescue
      raise("Unreachable, or incorrect permission to install #{required_gem}")
    end
  end

  require required_gem
end

class SplunkAPITestCLI
  include Mixlib::CLI

  option :url,
         :short => '-u URL',
         :long  => '--url URL',
         :default => 'https://localhost:8089',
         :required => false,
         :description => 'Splunkd URL to test'

  option :retries,
         :short => '-r RETRIES',
         :long  => '--retries RETRIES',
         :default => 5,
         :required => false,
         :description => 'Number of retries to attempt before failing'

  option :retry_interval,
         :short => '-i INTERVAL',
         :long => '--interval INTERVAL',
         :default => 18,
         :required => false,
         :description => 'Interval between retries in seconds'

  option :help,
         :short => '-h',
         :long => '--help',
         :description => "Display help for #{File.basename(__FILE__).gsub(/\..*/, '')}",
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0
end

cli = SplunkAPITestCLI.new
cli.parse_options

# Set up the logger
def log(level, msg)
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

# Set up the test procedure
def test(test_url, retries, retry_interval)
  # Set the response to nil to ensure a fail if we don't get anything back from Splunk.
  splunk_response = nil

  # Set up a common log message for ease of use and discoverability.
  log_msg = "Response code #{splunk_response || 'not'} returned from #{test_url}."

  time_start = Time.now
  log('info', "Starting Splunk API test at #{time_start}")
  until retries == 0 || splunk_response == 200 do
    retries = retries
    begin RestClient.get(test_url)
      splunk_response = RestClient.get(test_url).code.to_i
    rescue
      retries = retries - 1
      log('warn', "#{log_msg} #{Time.now.to_f - time_start.to_f} seconds since test start. #{retries} retries remaining.")
      sleep retry_interval
    end
  end

  if splunk_response != 200
    fatal_msg = "#{log_msg} No response received by #{Time.now} after #{Time.now.to_f - time_start.to_f} seconds."
    log('fatal', fatal_msg)
    raise(fatal_msg)
  else
    log('info', "Test of #{test_url} completed with response #{splunk_response} at #{Time.now} in #{Time.now.to_f - time_start.to_f} seconds.")
  end
end

test(cli.config[:url], cli.config[:retries].to_i, cli.config[:retry_interval].to_i)
