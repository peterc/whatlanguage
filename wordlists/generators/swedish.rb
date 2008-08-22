#!/usr/bin/env ruby

# Run this script to regenerate the Swedish wordlist.

# Data is from http://www.dsso.se/download.html
# under a Creative Commons ShareAlike license (http://creativecommons.org/licenses/sa/1.0/).

URL = "http://hem.bredband.net/dsso1/dsso-1.29.txt"
WORDLIST = File.join(File.dirname(__FILE__), '../swedish')

require "open-uri"
require "iconv"

puts "Fetching source data..."
data = open(URL)

puts "Writing to word list..."
open(WORDLIST, 'w') do |file|
  data.each do |line|
    next unless line =~ /^\d+r\d+<.+?>([^:]+)/
    line = $1

    line.gsub!(/\s*,\s*/, "\n")  # Some word variations are written like "word, variation"
    line = Iconv.iconv('UTF-8', 'ISO-8859-1', line)  # Convert Latin-1 to UTF-8
    
    file.puts(line)
  end
end

puts "All done."
