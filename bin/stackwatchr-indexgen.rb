#!/usr/bin/env ruby

listfile = ARGV[0]

indexlist = []
File.read(listfile).each_line do |line|
	indexlist << line.gsub("\n", "")
end

indexlist.each do |index|
	puts <<-EOF
[customer_#{index}]
homePath = $SPLUNK_DB/customer_#{index}/db
coldPath = $SPLUNK_DB/customer_#{index}/colddb
thawedPath = $SPLUNK_DB/customer_#{index}/thaweddb
repFactor = auto
disabled = 0

[customer_#{index}_os]
homePath = $SPLUNK_DB/customer_#{index}_os/db
coldPath = $SPLUNK_DB/customer_#{index}_os/colddb
thawedPath = $SPLUNK_DB/customer_#{index}_os/thaweddb
repFactor = auto
disabled = 0

EOF
end
