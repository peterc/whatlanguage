# Use this to build new filters (for other languages, ideally) from /usr/share/dict/words style dictionaries..
#
# Call like so..
#   ruby build_filter.rb /usr/share/dict/words lang/english.lang
# (replace params as necessary)

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'whatlanguage'
filter = WhatLanguage.filter_from_dictionary(ARGV[0])
File.open(ARGV[1], 'wb') { |f| f.write filter.dump }