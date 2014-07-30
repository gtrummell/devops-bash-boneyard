#!/usr/bin/env ruby

# Clear workspaces on executor nodes.
# Some stuff needs to be preconfigured, see below.

# Require gems
require "xmlsimple"
require "mixlib/cli"
require "net/ssh/multi"

# Set up CLI inputs
class CLI
  include Mixlib::CLI

  # Set up the default Jenkins directories
  ws_root = File.join("", "opt", "jenkins", "jobs", "Set", "workspace")

  option :stack_id,
         :short => "-s STACKID",
         :long  => "--stackid STACKID",
         :description => "Stack ID of the workspace to clear",
         :required => true

  option :workspace,
         :short => "-w WORKSPACE",
         :long  => "--workspace WORKSPACE",
         :default => ws_root,
         :description => "The path of the workspace",
         :required => true

  option :help,
         :short => "-h",
         :long => "--help",
         :description => "Show this message",
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0

  option :verbose,
         :short => "-v",
         :long  => "--verbose",
         :description => "Run verbosely",
         :boolean => true

  def parse!(argv = ARGV)
    parse_options(argv)
  end
end

# Parse command-line options
cli = CLI.new
cli.parse_options
stack_id = cli.config[:stack_id]
workspace = cli.config[:workspace]
verbose = cli.config[:verbose]

# Config stuff!
# This is a justa simple specialized script, so the following section
# is for any configuration items and should be changed if needed.
# Set the Jenkins config file location.
ssh_user = "jenkins"
stack_ws = File.join(workspace, stack_id)
config_file = File.join("", "opt", "jenkins", "config.xml")

# Read in the Jenkins config
config_xml = XmlSimple.xml_in(config_file, { "ForceArray" => false })

# Create the exec_hosts array and read the slaves into it
exec_hosts = []
config_xml["slaves"]["slave"].each { |slave| exec_hosts << "#{ssh_user}@#{slave["launcher"]["host"]}" }

Net::SSH::Multi.start do |session|
  # define the servers we want to use
  exec_hosts.each do |host|
    session.use host
    if verbose
      puts "Added #{host} to list of executors to be cleared"
    end
  end

  # execute commands on all servers
  session.exec "if [ ! -d #{stack_ws} ]; then echo "Directory does not exist on this executor"; else rm -rf #{stack_ws}; echo "Removed stack workspace from this executor"; fi"

  # run the aggregated event loop
  session.loop
end
