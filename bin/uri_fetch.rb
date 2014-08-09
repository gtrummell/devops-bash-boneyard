#!/usr/bin/env ruby

require 'net/https'
require 'chef'

class SecretURI
  def initialize(uri)
    @uri = uri
  end

  # DRY by setting up HTTP get operations as a private method.
  def _get_http
    http = Net::HTTP.new(@parsed_uri.host, @parsed_uri.port)
    http.use_ssl = true
    # noinspection RubyResolve
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.request(Net::HTTP::Get.new(@parsed_uri.request_uri))
  end

  def is_valid?
    # Check for URI validity:
    # - Does the URI parse successfully?  Return false if not.
    # - Is the URI scheme https?
    # - Is the request URI a path to a file and not a directory or nil?

    # First parse the URI.  Return false if parse fails.
    begin
      @parsed_uri = URI.parse(@uri)
    rescue
      puts "SecretURI: FATAL - Unable to parse URI #{@uri}"
      exit(false)
    end

    # Test the URI scheme for https and the request_uri for contents.
    puts "SecretURI::is_valid? - DEBUG Testing URI for proper formatting #{@parsed_uri}"
    if @parsed_uri.scheme == 'https' && @parsed_uri.request_uri != (/.*\/$/ || nil)
      puts "SecretURI::is_valid? - DEBUG Properly-formatted URI supplied, getting response from: #{@parsed_uri}..."
      begin
        response = _get_http.code.to_i
      rescue
        puts "SecretURI::is_valid? - FATAL Get error! unable to reach #{@parsed_uri}..."
        exit(false)
      end

      if response == 200
        puts "SecretURI::is_valid? - INFO Returned valid response from #{@uri[0...31]}..."
        true
      else
        puts "SecretURI::is_valid? - WARN Failure code #{response} received from #{@uri[0...31]}..."
        exit(false)
      end
    else
      puts "SecretURI::is_valid? - FATAL Improper URI scheme or request_uri supplied #{@uri[0...31]}..."
      exit(false)
    end
  end

  def get
    is_valid?
    puts "SecretURI::get - INFO Obtaining file from #{@uri[0...31]}..."
    begin
      response = _get_http
      puts response.body
    rescue
      puts "SecretURI::get - FATAL Unable to obtain file from #{@uri[0...31]}..."
      raise('Please stop the chef run if we get this far!')
    end
  end
end

test_secret = SecretURI.new('https://www.google.com/shopping/shortlists/l/a03019862603077963655?source=pshome-p4')
puts "\n### VALIDITY CHECK"
test_secret.is_valid?
puts "\n\n### GET CHECK"
test_secret.get