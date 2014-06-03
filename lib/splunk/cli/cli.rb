#
# Author:: Splunk Development Operations <splunk-whisper-accounts@splunk.com>
# Cookbook Name:: splunkwhisper
# Library:: splunk_cli
#
# Copyright 2012-2014, Splunk, Inc
#
# All Rights Reserved - Do not redistribute.
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Splunk License Whisper Library
# Performs licensing operations on the local machine to fill gaps in API
# and Ruby SDK Licensing functionality.
#

require 'open4'

class SplunkCLI

  class License
    attr_accessor(
        :file,
        :splunk_home,
        :username,
        :password
    )

    def initialize(hash, options = {})
      # Required arguments
      @lic_hash = hash

      # Optional arguments
      @lic_file = File.expand_path(options.fetch(:file)) || nil
      @splunk_home = options.fetch(:splunk_home) || File.join('', 'opt', 'splunk')
      @splunk_bin = File.join(@splunk_home, 'bin', 'splunk')
      @username = options.fetch(:username) || 'admin'
      @password = options.fetch(:password) || 'changeme'
    end

    def add(file)
      lic_file = file
      private_start_cli("add licenses #{lic_file}")
    end

    def exists?(hash)
      lic_hash = hash || @lic_hash
      private_start_cli('list licenses')
    end

    def private_start_cli(command)
      # Logging
      Chef::Log.info("whisper_license: Using license file #{@lic_file} for license hash #{@lic_hash}")
      Chef::Log.info('whisper_license: Authentication enabled') if @username && @password

      # Test for an installed Splunk
      unless File.exist?(File.join(@splunk_home, 'bin', 'splunk'))
        not_installed = 'whisper_license: Splunk is not installed!  Cannot continue!'
        Chef::Log.info(not_installed)
        raise(not_installed)
      end

      # Set up authentication if present
      (@username && @password) ?
          auth = "-auth #{@username}:#{@password}" :
          auth = ''

      # Set up the Splunk environment
      unless ENV['SPLUNK_HOME']
        (ENV['SPLUNK_HOME'] = @splunk_home)
      end

      system("#{@splunk_bin} #{command} #{auth}")
    end
  end

end
