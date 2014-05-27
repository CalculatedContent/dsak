#!/usr/bin/env ruby
#
# (c) 2014 Calculation Consulting <info@calculationconsulting.com>. All rights reserved.

require 'nokogiri'

doc = Nokogiri::XML($stdin.read)

puts doc.to_xhtml( indent:3, indent_text:" " )
