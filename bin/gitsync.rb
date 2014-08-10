#!/usr/bin/env ruby

# List of gems to install
libs = %w{git logger}

libs.each do |lib|
  gem_lib = lib.gsub(/-/, '/')
  begin
    gem gem_lib
  rescue
    begin
      system('gem install ' + lib)
      Gem.clear_paths
    rescue
      raise('Gem install failed. Permission to install system gems or RVM' +
        'required')
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
    rescue
      raise Exception 'Target must be a directory containing git' +
        'repositories' + dir
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

      raise Exception 'No repositories found in ' + @source_root if @repos
      .empty?
    rescue
      raise Exception 'Unable to search ' + @source_root
    end
  end

  # Open a directory as a Git repo.  Raise a warning if it's not a git repo.
  def _open_repo(dir)
    begin
      puts "Opening repo #{dir}"
      Git.open(dir, :log => Logger.new(STDOUT))
    rescue
      puts 'Not a git repository: ' + dir
    end
  end

  # Perform a Git Pull from the branch's remote.
  def _pull_repo(repo, branch)
    begin
      repo.checkout(branch)
      repo.pull
    rescue
      puts 'Unable to pull from source: ' + branch.to_s
    end
  end

  # Sync all the repos found in @source_root, parallelize by repo with threads.
  def sync
    _find_repos
    @repos.each do |repo|
      repo_thread = Thread.new do
        raise Exception 'Failed to open ' + repo unless
          (open_repo = _open_repo(repo))
        user_branch = open_repo.branch

        open_repo.branches.local.each do |branch|
          _pull_repo(open_repo, branch)
        end

        open_repo.checkout(user_branch)
      end
      repo_thread.abort_on_exception = true
      repo_thread.join
    end
  end
end

if ARGV.empty? || ARGV.include?('--help' || '-h')
  exit('Usage: gitsync <dir> [dir dir dir...]')
else
  ARGV.each do |dir|
    source_root_thread = Thread.new {
      git_dir = GitSync.new(dir)
      git_dir.sync
    }
    source_root_thread.abort_on_exception = true
    source_root_thread.join
  end
end