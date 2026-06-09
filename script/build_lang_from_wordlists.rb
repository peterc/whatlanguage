# Builds all of the word lists in ./wordlists/ into filter files in ./lang/

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'whatlanguage'

project_root = File.expand_path('..', __dir__)
languages_folder = File.join(project_root, "lang")
wordlists_folder = File.join(project_root, "wordlists")

Dir.entries(wordlists_folder).grep(/\w/).each do |lang|
  next if lang == 'generators'
  puts "Doing #{lang}"
  filter = WhatLanguage.filter_from_dictionary(File.join(wordlists_folder, lang))
  File.open(File.join(languages_folder, lang + ".lang"), 'wb') { |f| f.write filter.dump }
end
