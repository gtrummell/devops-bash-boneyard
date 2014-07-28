#!/usr/bin/env ruby

required_gems = %W{rest-client logger}

required_gems.each do |required_gem|
  begin
    gem required_gem
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
    log('info', "#{log_msg} Test completed at #{Time.now} in #{Time.now.to_f - time_start.to_f} seconds.")
  end
end

test('https://localhost:8089', 5, 5)
