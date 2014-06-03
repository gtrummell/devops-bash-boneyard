class InstanceSSH
  def initialize(vm, options = {})
    defaults = {
        :retries => 3
    }

    if options && options.is_a?(Hash)
      defaults.merge!(options)
    end

    @vm = vm
    @options = defaults
  end

  def ssh(command)
    @options[:retries].times do
      begin
        ret = @vm.run_ssh(command)
        return ret[0]
      rescue
        puts 'timeout, retrying'
      end
    end
    raise 'exhausted retries'
  end

  def run_ssh(command)
    puts(command)
  end

end