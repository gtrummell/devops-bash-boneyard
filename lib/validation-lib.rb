require "deep_merge"
require "json"
require "json-schema"

class ValidationLib
  def initialize(target)  # Read in the target file
    @target = JSON.parse(File.read(File.expand_path(target)))
    @schema = JSON.parse(File.read(File.expand_path(@target["schema"])))
    @level = level
  end

  def merge
    includes = @target["include_object"]

    parent = @target
    includes.nil? ?
        includes.each do |include|
          include_json = JSON.parse(File.read(include))
          rendered = parent.deep_merge(include_json)
          parent < rendered
        end :
        p "Includes are nil"

    @result = result
  end
  
  def validate
    errors = JSON::Validator.fully_validate(@schema, @result)
    errors.each { |error| p error }
  end
end
