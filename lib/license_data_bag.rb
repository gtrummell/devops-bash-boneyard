# TODO: Do requires in the proper way

require 'json'


class LicenseDataBag
  attr_accessor(
      :chef_config,
      :bag_id,
      :bag_name,
      :out_path
  )

  # Get information and set defaults
  def initialize(license, secret, options = {})
    # Required arguments
    @license = File.read(license)
    @secret = File.read(secret)

    # Options
    @chef_config = options.fetch(:chef_config)
    @bag_id = options.fetch(:bag_id) || File.basename(File.expand_path(license)).gsub(/\..*/, '')
    @bag_name = options.fetch(:bag_name) || 'whisper'
    @out_path = options.fetch(:out_path) || File.new(File.join('', 'dev', 'shm', "#{@bag_id}.json"))
  end

  # Test the input to make sure it's valid
  def private_test_input
    # TODO: See if license file exists and is valid
    # See if chef config file exists and is valid
    # See if the data bag item already exists
  end

  # Convert the license file to a data bag-friendly format
  def private_parse_license
    parsed_license = @license.gsub("\n", '').gsub("\"", "\\\n")

    # TESTING
    puts parsed_license
    parsed_license
  end

  # Write to a plain data bag in /dev/shm.
  def to_plain_databag(out_path)
    @out_path = out_path

      license_data = self.private_parse_license

      databag_file = ''

      license_unencrypted = {
          :id => "#{@bag_id}",
          xml_content: "#{license_data}"
      }

    license_json = JSON.parse(license_unencrypted)
  end

  # Write to an encrypted data bag
  # TODO: Write this in ruby and don't shell out
  def to_encrypted_databag
    self.to_plain_databag(@out_path)
    `knife data bag show #{}`
  end

end
