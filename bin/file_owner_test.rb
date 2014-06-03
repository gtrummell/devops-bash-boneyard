#!/user/bin/env ruby

require 'json'
require_relative '../lib/file_owner_test'

output_dir = '/Users/gtrummell/tmp'
output_file = File.join(output_dir, 'report.txt')

Dir.mkdir(output_dir) unless Dir.exist? (output_dir)
File.delete(output_file) if File.exist?(output_file)

match_file = MatchFileStat.new('/opt/splunk', 'root',
                               options = {
                                   #:group => "staff",
                                   #:target_perms => "755",
                                   :is_homedir => true
                                   #:passwd_file => "/etc/passwd",
                                   #:group_file => "/etc/group"
                               }
)

match_data = match_file.match_stats

match_report = File.open(output_file, 'w')
match_report << JSON.pretty_generate(match_data)
match_report.close

puts <<-EOF
Object data: #{JSON.pretty_generate(match_data[:target_obj])}
User mismatch count: #{match_data[:user_mismatch][:count]}
Group mismatch count: #{match_data[:group_mismatch][:count]}
Permission mismatch count: #{match_data[:perm_mismatch][:count]}
Target is user's home directory? #{match_data[:is_homedir]}
EOF