# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'whatlanguage/version'

Gem::Specification.new do |gem|
  gem.name          = "whatlanguage"
  gem.version       = WhatLanguage::VERSION
  gem.authors       = ["Peter Cooper"]
  gem.email         = ["git@peterc.org"]
  gem.description   = %q{WhatLanguage rapidly detects the language of a sample of text}
  gem.summary       = %q{Natural language detection for text samples}
  gem.homepage      = "https://github.com/peterc/whatlanguage"

  gem.files         = `git ls-files`.split($/).reject { |f| f.start_with?("wordlists") }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end