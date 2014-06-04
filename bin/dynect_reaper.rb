#!/usr/bin/env ruby

require 'fog'


module Fog
  def self.wait_for(timeout=1200, interval=Fog.interval, &block)
    duration = 0
    start = Time.now
    retries = 0
    until yield || duration > timeout
      sleep(interval.respond_to?(:call) ? interval.call(retries += 1).to_f : interval.to_f)
      duration = Time.now - start
    end
    if duration > timeout
      raise Errors::TimeoutError.new("The specified wait_for timeout (#{timeout} seconds) was exceeded")
    else
      {:duration => duration}
    end
  end
end

dynect = Fog::DNS.new(:provider => 'dynect',
                      :dynect_customer => '',
                      :dynect_username => '',
                      :dynect_password => '')

records = dynect.get_all_records('splunkwhisper.com')

all_splunkwhisper = []

records.data[:body]['data'].each { |item| all_splunkwhisper << item.gsub(/.*\/splunkwhisper.com\//, '').gsub(/\.splunkwhisper\.com\/.*/, '') }
