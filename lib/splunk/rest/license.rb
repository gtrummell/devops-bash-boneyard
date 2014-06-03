# License Class: Backing library for the whisper_license LWRP.
# This library reads a hash and the associated license file, verifies installation, and posts licenses.
#
# Required Parameters:
# hash      The hash associated with a license.  Currently, you must install a license on a test machine
#           first in order to get the hash.  TODO: Add computation functions
#
# Optional Parameters
# file      Path to the file containing the Splunk license.
# hostname  Hostname of the Splunk server to connect. Defaults to "localhost".
# port      Port on the Splunk server to connect. Defaults to 8089.
# use_https True to turn on SSL, false to turn it off.  Defaults to false.
# username  Splunkd username to present to the Splunk server.
# password  Password to present to the Splunk server.

require 'nokogiri'
require 'net/https'
require 'open3'

class License
  attr_accessor(
      :file,
      :hostname,
      :port,
      :use_https,
      :username,
      :password
  )


  # Initialize class instance:
  # Parse URI, license file, read private key, store auth credentials
  def initialize(hash, options = {})
    # Required arguments
    @lic_hash = hash

    # Optional arguments
    @lic_file = File.expand_path(options.fetch(:file)) || nil
    @hostname = options.fetch(:hostname) || 'localhost'
    @port = options.fetch(:port) || 8089
    @username = options.fetch(:username) || nil
    @password = options.fetch(:password) || nil

    # Set up the URI Scheme and build the URI
    options.fetch(:use_https) ? uri_scheme = 'https://' : uri_scheme = 'http://'

    @lic_uri = URI("#{uri_scheme + options.fetch(:hostname)}:#{options.fetch(:port).to_s}/services/licenser/licenses")

    # Logging
    Chef::Log.info("whisper_license: Querying Splunk server at #{hostname} for license hash #{@lic_hash}")
    Chef::Log.info("whisper_license: Opening license file #{@lic_file}") if @lic_file
    Chef::Log.info('whisper_license: SSL Enabled') if options.fetch(:use_https)
    Chef::Log.info('whisper_license: Authentication enabled') if @username && @password
  end

  def cli_add
    puts self.private_start_cli('status')[:stdout]
    puts self.private_start_cli('list')
  end

  # Method for creating licenses.  License file is specified in initialize
  # true - License installation successful
  # false - License installation failed
  def create
    Chef::Log.fatal('No license file is present! Create operations require a file specification.') unless File.exist?(@lic_file)

    lic_create_resp = self.private_start_http('create')

    lic_create_code = lic_create_resp.code.to_i
    lic_create_body = Nokogiri::XML.parse(lic_create_resp.body).text
    case lic_create_code
      when 201
        self.private_start_http('private_set_active_group', options = {:group => 'Enterprise'})
        Chef::Log.info('Splunkd: Created successfully. Restarting Splunk')
        self.private_start_http('private_restart')
        retry_count = 5
        until self.private_start_http('private_info') == 200 && retry_count == 0
          retry_count = (retry_count - 1)
          puts(self.private_start_http('private_info').body) && sleep(2)
        end
        true
      when 400
        Chef::Log.info("Splunkd (#{lic_create_code}): Request error. Response body:\n#{lic_create_body}")
        false
      when 401
        Chef::Log.fatal("Splunkd (#{lic_create_code}): Authentication failure: must pass valid credentials with request.")
        false
      when 402
        Chef::Log.fatal("Splunkd (#{lic_create_code}): The Splunk license in use has disabled this feature.")
        false
      when 403
        Chef::Log.fatal("Splunkd (#{lic_create_code}): Insufficient permissions to add a license.")
        false
      when 409
        Chef::Log.fatal("Splunkd (#{lic_create_code}): Request error: this operation is invalid for this item. Response body:\n#{lic_create_body}")
        false
      when 500
        Chef::Log.fatal("Splunkd (#{lic_create_code}): Internal server error. Response body:\n#{lic_create_body}")
        false
      when 503
        Chef::Log.fatal("Splunkd (#{lic_create_code}): This feature has been disabled in Splunk configuration files.")
        false
      else
        Chef::Log.fatal("Splunkd (#{lic_create_code}): Unknown Return Code. Response body:\n#{lic_create_body}")
    end
  end


  # Method for deleting a license
  # Sets the Free license to active.
  def delete
    unless self.private_start_http('delete').code.to_i == 200 &&
        self.private_start_http('private_verify_group', :group => 'Free')
      self.private_start_http('private_set_active_group', :group => 'Free')

      self.private_start_http('private_restart')
      retry_count = 5
      until self.private_start_http('private_info') == 200 && retry_count == 0
        retry_count = (retry_count - 1)
        puts(self.private_start_http('private_info').body) && sleep(2)
      end

    end
  end


  # Method for verifying that a license is installed.  Returns:
  # true - License installed
  # false - License not found
  def verify
    lic_verify_resp = self.private_start_http('verify')

    lic_verify_code = lic_verify_resp.code.to_i
    lic_verify_body = Nokogiri::XML.parse(lic_verify_resp.body).text

    case lic_verify_code
      when 200
        Chef::Log.info("Splunkd (#{lic_verify_code}): License file already installed.")
        true
      when 401
        Chef::Log.fatal("Splunkd (#{lic_verify_code}): Authentication failure: must pass valid credentials with request.")
        false
      when 403
        Chef::Log.fatal("Splunkd (#{lic_verify_code}): Insufficient permissions to view license.")
        false
      when 404
        Chef::Log.warn("Splunkd (#{lic_verify_code}): License does not exist.")
        false
      else
        Chef::Log.fatal("Splunkd (#{lic_verify_code}): Unknown Error. Response body:\n#{lic_verify_body}")
        false
    end
  end


  # Method for creating licenses locally via CLI
  # See if splunk is installed, running, and accepts license commands
  # Install and remove licenses
  def private_start_cli(action)
    # Setup
    splunk_bin_default = File.join('', 'opt', 'splunk', 'bin', 'splunk')

    Open3.popen3('/usr/bin/which splunk') do |stdin, stdout, stderr|
      splunk_bin_error_msg = "whisper_license: Splunk binary not found! Shell command data: STDIN: #{stdin.to_i}, STDOUT: #{stdout.gets}, STDERR: #{stderr.to_i}"

      if File.exist?(splunk_bin_default)
        @splunk_bin = splunk_bin_default
      elsif stdout.gets.to_s == /.*splunk.*/
        @splunk_bin = stdout.gets.to_s
      else
        Chef::Log.fatal(splunk_bin_error_msg)
        raise(splunk_bin_error_msg)
      end
    end

    ENV['SPLUNK_HOME'] = @splunk_bin.gsub(/\/bin\/splunk$/, '') unless ENV['SPLUNK_HOME']

    case action
      when 'status'
        cmd_line = 'status'
      when 'list'
        cmd_line = "list licenses -auth #{@username}:#{@password}"
      when 'install'
        cmd_line = "install #{@lic_file} -auth #{@username}:#{@password}"
      when 'remove'
        cmd_line = "remove licenses #{@lic_hash}"
      when 'restart'
        cmd_line = "restart -auth #{@username}:#{@password}"
      else
        action_error_msg = 'whisper_license: SplunkCLI missing or invalid command'
        Chef::Log.fatal(action_error_msg)
        raise(action_error_msg)
    end

    cli_output = {}
    Open3.popen3("/usr/bin/sudo #{@splunk_bin} #{cmd_line}") do |stdin, stdout, stderr|
      cli_output[:stdin] = puts(stdin.class)
      cli_output[:stdout] = puts(stdout.gets)
      cli_output[:stderr] = puts(stderr.to_i)
    end
  end


  # Private method to help DRY by combining common actions into a single method.
  def private_start_http(action, options = {})
    case action
      when 'create'
        request = Net::HTTP::Post.new(@lic_uri.path)
        request.body = "name=#{@lic_file}"
      when 'delete'
        request = Net::HTTP::Delete.new("#{@lic_uri.path}/#{@lic_hash}")
      when 'verify'
        request = Net::HTTP::Get.new("#{@lic_uri.path}/#{@lic_hash}")
      when 'private_info'
        request = Net::HTTP::Get.new('/server/info')
      when 'private_restart'
        request = Net::HTTP::Post.new('/server/control/restart')
      when 'private_set_active_group'
        request = Net::HTTP::Post.new("/services/licenser/groups/#{options.fetch(:group)}")
        request.body = 'is_active=1'
      when 'private_verify_group'
        request = Net::HTTP::Get.new("/services/licenser/groups/#{options.fetch(:group)}")
      else
        raise("whisper_license: FATAL: Unknown action specified \"#{action}\"")
    end

    request.basic_auth(@username, @password) if (@username && @password)

    Net::HTTP.start(@lic_uri.host, @lic_uri.port,
                    :use_ssl => @lic_uri.scheme == 'https',
                    :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |https| https.request(request) }
  end

end
