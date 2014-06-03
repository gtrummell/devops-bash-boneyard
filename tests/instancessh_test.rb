require_relative 'test_helper.rb'

# For now we are requiring the instancessh.rb file, but normally the rakefile takes care of this.
require_relative '../bin/instancessh'

class TestInstanceSSH < Minitest::Test
  def test_ssh
    vm_stub = InstanceSSH.stub(run_ssh, true)
    instance_ssh = InstanceSSH.new(vm_stub, options = {:retries => 0})

    instance_ssh.ssh('fakecommand')

    assert(ENV['BOOLEAN'], msg='This is a test!')
  end

end