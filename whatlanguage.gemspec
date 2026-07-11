# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'whatlanguage/version'

Gem::Specification.new do |gem|
  gem.name          = 'whatlanguage'
  gem.version       = WhatLanguage::VERSION
  gem.authors       = ['Peter Cooper']
  gem.email         = ['git@peterc.org']
  gem.description   = 'WhatLanguage rapidly detects the language of a sample of text'
  gem.summary       = 'Natural language detection for text samples'
  gem.homepage      = 'https://github.com/peterc/whatlanguage'
  gem.license       = 'MIT'
  gem.required_ruby_version = '>= 3.0'

  gem.files = Dir['lib/**/*'] + [
    'exe/whatlanguage',
    'README.md',
    'CHANGELOG.md',
    'LICENSE.txt',
    'Gemfile',
    'Rakefile',
    'whatlanguage.gemspec'
  ]
  gem.bindir        = 'exe'
  gem.executables   = ['whatlanguage']
  gem.require_paths = ['lib']

  gem.add_development_dependency 'minitest', '~> 5.0'
  gem.add_development_dependency 'rake'
end
