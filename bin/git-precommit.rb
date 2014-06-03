#!/usr/bin/env ruby

require 'git'


class TestRunner

  # Initialize: Figure out what project directory we're in, get a list of changed files.
  def initialize
    @project_dir = File.expand_path(__FILE__).gsub(/\/\.git.*/, '')

    changed_files = []
    Git::Base.open(@project_dir).status.each do |item|
      changed_files << File.expand_path(item.path) if item.type
    end
    @changed_files = changed_files
  end

  def run_tests
    self.private_test_chef
    self.private_test_ruby
  end

  # Detect the kind of file that's being committed: Find out if this file is in a chef-ey location and set type to chef.
  # We do this first to ensure we don't confuse chef files with normal Ruby files, based on location.
  def private_detect_type
    change_list = {}
    change_list[:chef_cookbooks] = []
    change_list[:ruby_files] = []

    temp_chef_cookbooks = []
    @changed_files.each do |file|
      if file.to_s.match('cookbooks')
        temp_chef_cookbooks << file.gsub(/.*\/cookbooks\//, '').split('/').first
        next
      else
        change_list[:ruby_files] << file
      end
    end

    change_list[:chef_cookbooks] = temp_chef_cookbooks.uniq!
    @change_list = change_list
  end

  # Perform Chef tests
  def private_test_chef
    if @change_list[:chef_cookbooks]
      @change_list[:chef_cookbooks].each do |cookbook|
        `/usr/bin/env foodcritic #{@project_dir}/chef/cookbooks/#{cookbook}`
        `/usr/bin/env knife cookbook test #{cookbook}`
      end
    else
      puts('No cookbooks detected.')
    end
  end

  # Perform Ruby tests
  def private_test_ruby
    if @change_list[:ruby_files]
      `rake minitest`
      @change_list[:ruby_files].each do |rubyfile|
        `rubocop #{rubyfile}`
      end
    else
      puts('No Ruby files detected.')
    end
  end

end

test_files = TestRunner.new

test_files.run_tests
