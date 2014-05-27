#!/usr/bin/env ruby
#
# (c) 2014 Calculation Consulting <info@calculationconsulting.com>. All rights reserved.

require 'csv'
require 'trollop'

opts = Trollop::options do
  version "0.1"
  banner <<-EOS
Extract CSV fields from STDIN and outputs them in columns to a tab delimited file

Examples:
      #{$0} -f "revenues" > myfile.txt    # each record (line) of stdin will be parsed as CSV and the output file will have one column

      cat myfile.csv | #{$0} -f 1                          # index match (starting at 1 like AWK) on a single column
      cat myfile.csv | #{$0} -f "date" -f "revenues"       # multiple columns (exact match)
      cat myfile.csv | #{$0} -f "/revenue(s)?/"            # [NOT IMPLEMENTED] regexp match
      cat myfile.csv | #{$0} -f "date" -s ","              # output CSV instead of default Tab separated
      cat myfile.csv | #{$0} -h                            # print the header (with AWK column numbers) and exit

      cat myfile.csv| #{$0} -i   # ignore lines that are not JSONS without crashing (uselful to skip header)

TODO:
  - same thing as we do everyday Pinky, take over the world
  - implement regexp matching of the field names
  - option to strip Tabs from fields

Usage:
      #{$0} [options] < myfile.csv
where [options] are:
EOS
  # Input
  opt :ignore, "ignore non CSV lines (instead of crashing for CSV parse error)", :short => "-i",  :default => false
  # Output
  opt :field, "field to extract", :multi => true, :default => ["1"]
  opt :separator, "character separating the columns (when multiple fields are selected)", :default => "\t"
  opt :no_header, "by default assume the first non empty line is a header", :default => false
  opt :header_print, "print header (with numerical index) as TSV and exit", :short => "-h", :default => false
  opt :header_keep, "keep the header", :short => "-k", :default => false
  opt :downcase, "downcase all output", :default => false
end

header_line = ''
header2index = {}
nb_lines = 0

def is_numeric?(obj)
    Float(obj) != nil rescue false
end

$stdin.each do |line|
  next if line.empty?

  fields = []
  begin
    str = CSV.parse(line)
    row = str[0]

    # parse the header
    nb_lines += 1
    is_header = nb_lines == 1
    if is_header
      header_line = line
      index = 0
      row.each do |col|
        header2index[col] = index
        index += 1
      end
      if opts[:header_print] then
        header2index.keys.each_with_index do |key,index| puts "#{key}\t#{index+1}" end
        exit
      end

      puts header_line unless header_line.empty? or !opts[:header_keep]

      next
    end

    opts[:field].each do |field|
      index = field
      if is_numeric?(field) then
        index = field.to_i
        index = 1 unless index > 1
        index = index-1
      else
        next if !header2index.has_key?(field)
        index = header2index[field]
      end

      value = row[index].to_s.strip
      next unless !value.empty?

      value.downcase! unless !opts[:downcase]
      fields.push(value)
    end
  rescue => e
    raise e unless opts[:ignore]
    next
  end

  next unless fields.size

  puts fields.flatten.join(opts[:separator])
end
