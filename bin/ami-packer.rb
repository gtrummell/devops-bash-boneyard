#!/usr/bin/env ruby -w
#
# Ruby shell script to run packer.io to build an AMI.

require "rubygems"
require "mixlib/cli"
require "net/http"
require "zip"

include FileUtils

#
# Set up CLI commands
#

class AMIPackerCli
  include Mixlib::CLI

  option :template,
         :short => "-t TEMPLATE",
         :long  => "--template TEMPLATE",
         :default => "~/etc/packer-templates/default.json",
         :required => true,
         :description => "The Packer.io template file to use"

  option :custom_script,
         :short => "-s SCRIPT",
         :long => "--script SCRIPT",
         :default => "~/etc/packer-scripts/default.sh",
         :required => false,
         :description => "Custom script to run after the provisioner template"

  option :packer_url,
         :short => "-u URL",
         :long => "--url URL",
         :default => "https://dl.bintray.com/mitchellh/packer/0.4.1_linux_amd64.zip",
         :require => false,
         :description => "Source URL for Packer.io - defaults to Linux AMD64"

  option :verbose,
         :short => "-v",
         :long  => "--verbose",
         :boolean => true,
         :required => false,
         :description => "Verbose output"

  option :help,
         :short => "-h",
         :long => "--help",
         :description => "Show this message",
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0

end

# Parse CLI options
# ARGV = [ '-t', 'foo.json', '-s', 'bar.sh' -v ]

cli = AMIPackerCli.new
cli.parse_options

template = File.expand_path(cli.config[:template])
custom_script = File.expand_path(cli.config[:custom_script])
packer_url = cli.config[:packer_url]
packer_uri = URI.parse(packer_url)
verbose = cli.config[:verbose]

!verbose if verbose.nil?

# Set variables
packer_local = packer_uri.path.split("/").last

# Check if we're running verbosely - tell the user what we know as soon as we know it.
if verbose
  puts "Startup: Using template #{template}"
  puts "Startup: Using custom script #{custom_script}"
  puts "Startup: Getting packer from #{packer_url}"
  puts "Startup: Downloading to #{packer_local}"
end


#
# Define methods
#

def get_packer(url)
  url.nil? ? abort("get_packer: URL is empty. Cannot continue.") : packer_uri = URI.parse(url)

  outpath = File.join(pwd(), packer_uri.path.split("/").last)

  packer_source_port = 443 if packer_uri.scheme == "https"
  packer_source = Net::HTTP.new(packer_uri.host, packer_source_port)
  packer_source.use_ssl = true if packer_uri.scheme == "https"

  packer_source.start do |download|
    response = download.request_get(packer_uri.path)
    File.open(outpath, "wb") do |outfile|
      outfile.write(response.body)
      outfile.flush
      outfile
    end
  end
end


def unzip_packer(zipfile)
  if zipfile.nil?
    abort("unzip_packer: File is empty. Cannot continue")
  else
    Zip::ZipFile.open(zipfile) do |entry|
      entry.each do |file|
        file.extract
      end
    end
  end

end


def validate(templ)
  system("packer validate #{File.expand_path(templ)}")

  return $?
end


def build(templ, script)
  if templ.nil?
    abort("packer_build: No template specified!")
  end

  if script.nil?
    abort("packer_build: No script specified!")
  end

  system("packer build -var 'custom_script=#{script}' #{templ}")

  return $?
end

#
# Go to work
#


puts "Getting Packer.io from #{packer_url}" if verbose
get_packer(packer_url)

puts "Unzipping Packer.io from #{packer_local}" if verbose
unzip_packer(packer_local)

puts "Validating Template #{template}" if verbose
if validate(template)
  puts "Running Packer.io with template #{template} and custom script #{custom_script}" if verbose
  build(template, custom_script)
else
  puts $?
  abort("Failed to validate #{template}")
end