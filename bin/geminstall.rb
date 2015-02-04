#!/usr/bin/env ruby

require 'chef/resource/chef_gem'

gem_list = {
#  'chef-vault' => '1.2.0',
  'spiceweasel' => '2.8.0',
  'knife-cloudformation' => '0.2.10'
}

def gem_install(source='https://rubygems.org', name='', version='')
  begin
    gem_installer = Chef::Resource::ChefGem.new("chef-vault")
    gem_installer.version version
    gem_installer.options "--clear-sources --source #{source}"
    gem_installer.action :install
    gem_installer.after_created

    require 'chef-vault'
  end
end

gem_list.each do |k,v|
  gem_install.new(name=k, version=v)
end