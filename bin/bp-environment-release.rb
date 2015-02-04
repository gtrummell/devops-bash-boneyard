required_gems = %W{chef git logger mixlib/cli}

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

class BPEnvReleaseCLI
  include Mixlib::CLI

  option :environment,
         :short => '-e ENVIRONMENT',
         :long  => '--env ENVIRONMENT',
         :default => 'development',
         :required => true,
         :description => 'Chef Environment being released'

  option :cookbook,
         :short => '-c COOKBOOK[,COOKBOOK[,COOKBOOK]]...',
         :long  => '--cookbooks COOKBOOK',
         :default => 5,
         :required => true,
         :description => "Cookbooks to release or 'all'"

  option :chefconfig,
         :short => '-f CONFIG-FILE',
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

cli = BPEnvReleaseCLI.new
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

# Set up the Repo class
class BPRepo()

end

# Set up the EnvObject class