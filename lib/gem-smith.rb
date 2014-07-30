require "pp"

class GemSmith
  # Initialize the class object.
  def initialize(gemfile)
    @gemfile = File.expand_path(gemfile)
  end

  # Grep the project for files that call gems
  def scan_project
    # Get the project directory from the Gemfile
    projectdir = File.dirname(@gemfile)

    # Get a list of files in the project that call gems
    projectfiles = []
    Dir.glob("#{projectdir}/**/*").select do |file|
      projectfiles << File.expand_path(file) if File.file?(file)
    end

    # Get an array of hashes containing a filename, gem, and version
    proj_gemlines = []
    # For each file in the project...
    projectfiles.each do |file|
      file_gemlines = []
      # Break the file up into an array containing lines.
      File.read(File.expand_path(file)).each_line do |line|
        # Only include lines that call a gem with "gem" or "require".  Skip lines that don't.
        line_array = []
        (line.match(/^require ["']/) || line.match(/^gem ["']/)) ?
            line_array << line.gsub(/:.*/, "").gsub(/[",]/, "").split(" ") :
            next
        line_array.flatten!

        # Extract the gem name from the array.
        (line_array[1] == /^[.\/\w]/) ?
          gem = (File.basename(File.expand_path(line_array[1]))).gsub(/-\d+\.*/, "") :
          gem = line_array[1].gsub(/\//, "-")

        # Extract the version number from the array
        line_array.include?(/[><!=]/) ?
          version = line_array[2] :
          version = ""

        # Append a new hash to the file_gemlines array containing filename, gem, and version.
        file_gemlines << { filename: file, gem: gem, version: version }
      end
      # Put this file's results into the global variable, @gemlines.
      file_gemlines.each do |file_gemline|
        proj_gemlines << file_gemline
      end
      proj_gemlines
    end
    @gemlines = proj_gemlines
  end

  def list_required
    files = []
    @gemlines.each do |gemline|
      files << gemline[:gem] if File.basename(gemline[:filename]) == "Gemfile"
    end
    files.uniq.sort
  end

  def list_gemfile
    files = []
    @gemlines.each do |gemline|
      files << gemline[:gem] if File.basename(gemline[:filename]) != "Gemfile"
    end
    files.uniq.sort
  end

end
