#!/usr/bin/env ruby

# List of gems to install
libs = %w{git logger}

libs.each do |lib|
  gem_lib = lib.gsub(/-/, '/')
  begin
    gem gem_lib
  rescue => err_parent
    begin
      puts("Gem #{gem_lib} not present. Attempting install.\n#{err_parent}")
      system('gem install ' + lib)
      Gem.clear_paths
    rescue => err_child
      raise(puts('Gem install failed. Permission to install ' +
        "system gems or RVM required!\n#{err_parent}\n#{err_child}"))
    end
  end

  require gem_lib
end

# Class for git operations
class GitSync
  # Initialize operations against a directory.  Fail if the directory
  # doesn't exist, or if the user has specified a file.
  def initialize(dir)
    begin
      if Dir.exists?(File.expand_path(dir))
        @source_root = File.expand_path(dir)
      end
    rescue => err
      _logger('warn', 'Target must be a directory containing git ' +
        "repositories: #{dir}\n#{err}")
      false
    end
  end

  # Get a list of all directories containing a .git configuration dir
  def _find_repos

    begin
      repos = []
      Dir.glob(File.join(@source_root, '**/.git')).each do |dir|
        repos << dir.gsub(/\/\.git$/, '')
      end
      @repos = repos

      _logger('warn', 'No repositories found in ' + @source_root) if
          @repos.empty?
    rescue => err
      _logger('fatal', 'Unable to search ' + @source_root + "\n" + err)
    end
  end

  # Configure a logger instance
  def _logger(severity, message, options={})
    err = options[:error]
    log_msg = Logger.new(STDOUT)

    case severity
      when 'info'
        log_msg.info(message)
        log_msg.info(err) if err
      when 'warn'
        log_msg.warn(message)
        log_msg.warn(err) if err
      when 'fatal'
        log_msg.fatal(message)
      else
        log_msg.fatal(message)
    end
  end

  # Open a directory as a Git repo.  Raise a warning if it's not a git repo.
  def _open_repo(dir)
    begin
      _logger('info', 'Opening repo ' + dir)
      Git.open(dir, :log => Logger.new(STDOUT))
    rescue => err
      _logger('warn', "Not a git repository: #{dir}\n#{err}")
    end
  end

  # Perform a Git Pull from the branch's remote.
  def _pull_repo(repo, branch)
    begin
      repo.checkout(branch)
      repo.pull
    rescue => err
      _logger('warn', "Unable to pull from source for #{repo
      .dir}/#{branch}\n#{err}")
    end
  end

  # Sync all the repos found in @source_root, parallelize by repo with threads.
  # Remember which branch the user had checked out and check it out for them
  # again.
  def sync
    begin
      _find_repos
      @repos.each do |repo|
        next unless (open_repo = _open_repo(repo))
        user_branch = open_repo.current_branch

        open_repo.branches.local.each do |branch|
          _pull_repo(open_repo, branch)
        end

        open_repo.checkout(user_branch)
      end
    rescue => err
      _logger('fatal', "Fatal repository sync error!\n#{err}")
      raise err
    end
  end
end

# Command line logic for all-in-one Ruby Script utility
if ARGV.empty? || ARGV.include?('--help' || '-h')
  puts 'Usage: gitsync <dir> [dir dir dir ...]'
  exit 3
else
  ARGV.each do |dir|
    source_root_thread = Thread.new {
      git_dir = GitSync.new(dir)
      git_dir.sync
    }
    source_root_thread.join
  end
end
