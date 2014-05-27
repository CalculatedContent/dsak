#!/usr/bin/env ruby
#
# (c) 2014 Calculation Consulting <info@calculationconsulting.com>. All rights reserved.

require 'trollop'
require 'json'

opts = Trollop::options do
  version "0.1"
  banner <<-EOS
Prettify a JSONS file.
Note that the output is no longer JSONS but a JSON file.

Examples:
      cat myfile.jsons | #{$0} > newfile.json
      cat myfile.jsons | #{$0} -i   # ignore lines that are not JSONS without crashing (uselful to skip header)

Usage:
      cat file | #{$0} [options]
where [options] are:
EOS
  opt :ignore, "ignore non JSON lines (instead of crashing for JSON parse error)", :short => "-i",  :default => false
end

$stdin.each do |line|
  begin
    str = JSON.parse(line)
    puts JSON.pretty_generate(str)
  rescue => e
    raise e unless opts[:ignore]
    next
  end
end
