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
      cat myfile.csv | #{$0} -f "date,revenues"            # multiple columns (exact match) [same as previous example]
      cat myfile.csv | #{$0} -f "/revenue(s)?/"            # regexp match
      cat myfile.csv | #{$0} -f "date" -s ","              # output CSV instead of default Tab separated
      cat myfile.csv | #{$0} -h                            # print the header (with AWK column numbers) and exit

      cat myfile.csv| #{$0} -i   # ignore lines that are not CSV without crashing (uselful to skip malformed header)

TODO:
  - same thing as we do everyday Pinky, take over the world
  X implement regexp matching of the field names
  - option to strip Tabs from fields
  x support comma-separated -f
  x support for ranges in -f like 1..3 or 1.. or 1..-1
  X BUG: header_keep should print only the selected columns
  X FEATURE: 'fast' option that uses tokens instead of CSV parse (but beware of the caveats if some values have commas)

Usage:
      #{$0} [options] < myfile.csv
where [options] are:
EOS
  # Input
  opt :field, "fields to extract (by default extract all)", :multi => true, :default => [""]
  opt :ignore, "ignore non CSV lines (instead of crashing for CSV parse error)", :short => "-i",  :default => false
  opt :header_case_smart, "use smartcase to match header columns", :default => true
  opt :header_case_ignore, "ignore case to match header columns (takes precendence over smart case)", :default => false
  opt :separator, "character separating the columns (when multiple fields are selected)", :default => ","
  # Output
  opt :out_separator, "character separating the columns for the output", :short => "-o", :default => "\t"
  opt :fast, "when parsing CSV (separator is a comma), split line by tokens instead of using the CSV parser (faster but can lead to problems if the fields have commas in them)", :default => false
  opt :header_print, "print header as TSV and exit (index starts at 1 to be AWK friendly)", :short => "-h", :default => false
  opt :header_keep, "keep the header", :short => "-k", :default => true
  opt :downcase, "downcase all output", :default => false
  opt :debug, "output debug information", :short => "-d", :default => false
end

$debug = opts[:debug]
def log str
  $stderr.puts str unless !$debug
end

def is_regexp str
  if str.start_with?('/') && str.end_with?('/') then
    return true
  end
  return false
end

# Ordered list of user-requested fields (can be numeric or strings)
# Ex:
#   'name'    => 0
#   'address' => 1
#   '1'       => 2 (user requested the first column 1)
#   '/flag*/' => 3 (user requested columns matching a regexp)
columns_requested = {} # expand -f options

opts[:field].each do |col|
  index = 0
  col.strip.split(opts[:separator]).each do |column|
    column.strip!

    next if column.empty?

    columns_requested[column] = index
    index += 1
  end
end

header_found = false
header2index = {} # index of all the columns (even the ones we don't keep for output)
header_size = 0
columns2index = {} # index of the columns we keep
nb_lines = 0

def is_numeric?(obj)
    Float(obj) != nil rescue false
end

use_csv = false unless (opts[:separator] == ',' and !opts[:fast])

$stdin.each do |line|
  line.strip!

  next if line.empty?

  fields = []
  begin
    str = ''
    row = []
    if use_csv then
      str = CSV.parse(line)
      row = str[0]
    else
      row = line.split(opts[:separator])
    end

    row_size = row.size
    next unless row_size>0

    # parse the header
    nb_lines += 1
    is_first_line = nb_lines == 1
    if is_first_line then

      # record all the header columns
      row.each do |col|
        header2index[col] = header_size
        header_size += 1
      end
        
      header_found = true
      
      # match the header with the columns requested
      if columns_requested.size==0 then
          # no columns where requested so by default we will get all the columns
          columns2index = header2index
      else
        columns_requested.keys.each do |col_req|
          if is_numeric? col_req then
            req_index = col_req.to_i
            nb_columns = header2index.size
            if req_index<1 then
             log "Columns are 1-based: #{col_req} requested"
            elsif req_index > nb_columns then
              log "Header has only #{nb_columns} columns: column '#{col_req}' requested"
            else
              actual_index = req_index - 1
              column_names = header2index.keys
              column_name = column_names[actual_index]
              columns2index[column_name] = actual_index
            end
          else
            use_regexp = false
            regexp = ''
            if is_regexp col_req then
              use_regexp = true
              regexp = col_req.chop # remove trailing /
              regexp[0] = ''        # remove leading /
            end
      
            header2index.each do |column_name, index|
              match = false
              if use_regexp then
                if opts[:header_case_ignore] then
                  if column_name =~ /#{regexp}/i then
                    match = true
                  end
                else
                  if column_name =~ /#{regexp}/ then
                    match = true
                  end
                end
              else
                if opts[:header_case_ignore] then
                  match = true unless col_req.downcase != column_name.downcase
                else
                  match = true unless col_req != column_name
                end
              end

              columns2index[column_name] = index unless !match
            end

          end
        end
      end

      if opts[:header_print] then
        columns2index.keys.each_with_index do |key,index| puts "#{key}#{opts[:out_separator]}#{index+1}" end
        exit
      end

      puts columns2index.keys.flatten.join(opts[:out_separator]) unless !opts[:header_keep] or columns2index.keys.size==0

      next
    end

    if opts[:debug] and header_found then
        if row_size > header_size then
          log "Line #{nb_lines}: too many fields (#{row_size} while header has #{header_size} fields)"
        end
        if row_size < header_size then
          log "Line #{nb_lines}: missing fields (#{row_size} while header has #{header_size} fields)"
        end
    end

    columns2index.values.each do |index|
      value = row[index].to_s.strip

      value.downcase! unless !opts[:downcase]
      fields.push(value)
    end

  rescue => e
    raise e unless opts[:ignore]
    next
  end

  next unless fields.size > 0

  puts fields.flatten.join(opts[:out_separator])
end
