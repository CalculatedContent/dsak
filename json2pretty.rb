#!/usr/bin/env ruby
#
# (c) 2014 Calculation Consulting <info@calculationconsulting.com>. All rights reserved.

require 'json'

str = JSON.parse($stdin.read)
puts JSON.pretty_generate(str)
