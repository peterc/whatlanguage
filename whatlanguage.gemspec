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
  gem.license       = "MIT"
  gem.required_ruby_version = ">= 3.0"

  gem.files         = Dir["lib/**/*"] + [
    "README.md",
    "CHANGELOG.md",
    "LICENSE.txt",
    "Gemfile",
    "Rakefile",
    "whatlanguage.gemspec"
  ]
  gem.require_paths = ["lib"]

  gem.add_development_dependency "minitest", "~> 5.0"
  gem.add_development_dependency "rake"
end
