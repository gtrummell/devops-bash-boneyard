#!/usr/bin/env ruby

# Clear workspaces on executor nodes.
# Some stuff needs to be preconfigured, see below.

# Require gems
require "xmlsimple"
require "jenkins_api_client"
require "mixlib/cli"
require "uri"
require "pp"

# Set up CLI inputs
class CLI
  include Mixlib::CLI

  option :jenkins_url,
         :short => "-u URL",
         :long  => "--url URL",
         :default => "https://your.server.here/",
         :description => "The URL of the Jenkins Server",
         :required => true

  option :jenkins_port,
         :short => "-p PORT",
         :long  => "--port PORT",
         :default => "443",
         :description => "The authorized port to connect to the Jenkins Server",
         :required => true

  option :jenkins_ssl,
         :short => "-s",
         :long => "--ssl",
         :default => true,
         :description => "Enable Jenkins SSL (Default is false)",
         :boolean => true,
         :required => false

  option :jenkins_user,
         :short => "-n USERNAME",
         :long  => "--username USERNAME",
         :description => "The username to provide the Jenkins Server",
         :required => true

  option :jenkins_pass64,
         :short => "-w PASSWORD64",
         :long  => "--password PASSWORD64",
         :description => "The base64-encoded password for the Jenkins User",
         :required => true

  option :verbose,
         :short => "-v",
         :long  => "--verbose",
         :description => "Run verbosely",
         :boolean => true,
         :required => false

  option :help,
         :short => "-h",
         :long => "--help",
         :description => "Show this message",
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0


  def parse!(argv = ARGV)
    parse_options(argv)
  end
end

# Parse command-line options
cli = CLI.new
cli.parse_options
jenkins_url = cli.config[:jenkins_url]
jenkins_port = cli.config[:jenkins_port]
jenkins_ssl = cli.config[:jenkins_ssl]
jenkins_user = cli.config[:jenkins_user]
jenkins_pass64 = cli.config[:jenkins_pass64]
verbose = cli.config[:verbose]

# Initialize the connection to the Jenkins Server
jenkins_client =  JenkinsApi::Client.new(:server_url => jenkins_url,
                                  :server_port => jenkins_port,
                                  :ssl => jenkins_ssl,
                                  :username => jenkins_user,
                                  :password_base64 => jenkins_pass64)

# List the nodes we will be deleting
if verbose
  nodelist = jenkins_client.node.list
  pp "Found the following nodes:"
  nodelist.each do |node|
    pp node unless node == "master"
  end
end

# Do the delete
jenkins_client.node.delete_all!
