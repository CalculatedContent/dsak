#!/usr/bin/env ruby
#
# (c) 2014 Calculation Consulting <info@calculationconsulting.com>. All rights reserved.

require 'json'
require 'trollop'

opts = Trollop::options do
  version "0.1"
  banner <<-EOS
Extract JSON fields from STDIN and outputs them in columns to a Tab delimited file

Examples:
      #{$0} -f "revenues" > myfile.txt    # each record (line) of stdin will be parsed as JSON and the output file will have one column

      cat myfile.jsons | #{$0} -f "date" -f "revenues"       # multiple columns (exact match)
      cat myfile.jsons | #{$0} -f "/revenue(s)?/"            # [NOT IMPLEMENTED] regexp match
      cat myfile.jsons | #{$0} -f "date" -s ","              # output CSV instead of Tab separated (default)

      cat myfile.jsons | #{$0} -i   # ignore lines that are not JSONS without crashing (uselful to skip header)

TODO:
  - same things as we do everyday Pinky, dominate the world
  - implement regexp matching of the field names

Usage:
      #{$0} [options] < myfile.json
where [options] are:
EOS
  # Output
  opt :field, "field to extract", :multi => true, :default => [""]
  opt :separator, "character separating the columns (when multiple fields are selected)", :default => "\t"
  opt :ignore, "ignore non JSON lines (instead of crashing for JSON parse error)", :short => "-i",  :default => false
end

$stdin.each do |line|
  begin
    str = JSON.parse(line)
  rescue => e
    raise e unless opts[:ignore]
    next
  end
  fields = []
  opts[:field].each do |field|
    if str.has_key?(field) then
      value = str[field].to_s
      fields.push(value)
    end
  end
  puts fields.flatten.join(opts[:separator]) unless !fields.size
end
