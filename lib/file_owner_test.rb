require 'etc'

class MatchFileStat

  attr_accessor(
      :group,
      :target_perms,
      :is_homedir,
      :passwd_file,
      :group_file
  )

  # Initialize an instance of the MatchFileStat class
  def initialize(target_obj, user, options = {})
    # Required Arguments
    @target_obj = File.expand_path(target_obj)
    @user = user

    # Optional Arguments
    @group = options[:group] || nil
    @target_perms = options[:target_perms] || nil
    @is_homedir = options[:is_homedir]
    @passwd_file = options[:passwd_file] || File.expand_path('/etc/passwd')
    @group_file = options[:group_file] || File.expand_path('/etc/group')
  end

  def match_stats
    # Set up by getting the passwd and group files, and the target object hash
    etc_passwd = self.private_hash_passwd
    targets = self.private_hash_target_obj
    if @group
      etc_group = self.private_hash_group
    else
      etc_group = ''
    end

    # Set up a hash to send results.
    results = {
        :target_obj => {
            :path => @target_obj,
            :target_user => @user,
            :target_group => @group,
            :target_perms => @target_perms,
            :passwd_file => @passwd_file,
            :group_file => @group_file
        },
        :user_mismatch => {},
        :group_mismatch => {},
        :perm_mismatch => {},
        :is_homedir => false
    }

    # Test the file to see if it matches the requested user.  This is the default return.
    targets.each do |target, hash|
      next if hash[:uid] == etc_passwd[:uid]
      results[:user_mismatch].merge!({target => hash})
    end
    results[:user_mismatch][:count] = results[:user_mismatch].keys.count

    # Test the file to see if it matches the requested group. This is optional.
    if @group
      targets.each do |target, hash|
        next if hash[:gid] == etc_group[:gid]
        results[:group_mismatch].merge!({target => hash})
      end
    end
    results[:group_mismatch][:count] = results[:group_mismatch].keys.count

    # Test the file to see if its permissions match the requested user.  This is optional.
    unless @target_perms.nil?
      targets.each do |target, hash|
        next if hash[:perms] == @target_perms
        results[:perm_mismatch].merge!({target => hash})
      end
    end
    results[:perm_mismatch][:count] = results[:perm_mismatch].keys.count

    # Test the target and find out if it's the user's home directory

    results[:is_homedir] = true if @is_homedir &&
        File.directory?(targets.to_s.chomp) &&
        targets.to_s.chomp == etc_passwd[:homedir]

    # Return the results hash
    results
  end

  #
  # Private Methods
  #

  # Convert passwd file into a hash
  def private_hash_passwd
    # First test for the existence of the passwd file
    raise ("MatchFileStat: Could not read passwd file #{@passwd_file}") unless File.exist?(@passwd_file)

    # Perform the hash conversion
    etc_passwd = {}
    File.read(File.expand_path(@passwd_file)).each_line do |line|
      next if line.match(/^#.*/)

      user = line.gsub("\n", '').split(':')
      next unless user[0] == @user

      passwd_line = {
          :user => user[0],
          :status => user[1],
          :uid => user[2].to_i,
          :gid => user[3].to_i,
          :comment => user[4],
          :homedir => user[5],
          :shell => user[6]
      }
      etc_passwd.merge!(passwd_line)
    end

    raise("User #{@user} not found in #{@passwd_file}") if etc_passwd.nil? or etc_passwd.empty?

    etc_passwd
  end

  # Convert the groups file into a hash
  def private_hash_group
    # First test for the existence of the group file
    raise ("MatchFileStat: Could not read groups file #{@group_file}") unless File.exist?(@group_file)

    # Perform the hash conversion
    etc_group = {}
    File.read(File.expand_path(@group_file)).each_line do |line|
      next if line.match(/^#.*/)

      group = line.split(':')
      next unless group[0].to_s.chomp == @group

      group_line = {
          :group => group[0],
          :status => group[1],
          :gid => group[2].to_i,
          :members => group[3].split(',')
      }
      etc_group.merge!(group_line)
    end

    raise("Group #{@group} not found in #{@group_file}") if etc_group.nil? or etc_group.empty?

    etc_group
  end

  # Gather information about the target object(s) and put them in a hash
  # @return [Object]
  def private_hash_target_obj
    # Raise an error if the target object doesn't exist.
    raise("Target object does not exist!  Path: #{@target_obj}") unless File.exist?(@target_obj)

    # Find out if we're dealing with a file or directory, raise error if neither
    if File.directory?(@target_obj)
      # Get a list of files in @target_obj.
      target_glob = Dir.glob("#{@target_obj}/**/*")
    elsif File.file?(@target_obj)
      target_glob = @target_obj
    else
      raise("Object is neither file nor directory! #{@target_obj}}")
    end

    # Generate a hash for the target file(s). Get UID, GID, and permissions
    target_files = {}
    target_glob.each do |target|
      target_entry = {
          target.to_s => {
              :uid => File.stat(target).uid.to_i,
              :gid => File.stat(target).gid.to_i,
              :perms => File.stat(target).mode.to_s(8).split(//).last(4).join.to_i
          }
      }
      target_files.merge!(target_entry)
    end

    raise('No target files found!') if target_files.nil? or target_files.empty?

    target_files
  end

end