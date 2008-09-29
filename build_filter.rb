# Use this to build new filters (for other languages, ideally) from /usr/share/dict/words style dictionaries..
#
# Call like so..
#   ruby build_filter.rb /usr/share/dict/words lang/english.lang
# (replace params as necessary)

require 'lib/whatlanguage'
filter = WhatLanguage.filter_from_dictionary(ARGV[0])
File.open(ARGV[1], 'wb') { |f| f.write filter.dump }