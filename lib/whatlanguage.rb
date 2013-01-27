require File.join(File.dirname(__FILE__), 'bloominsimple')
require 'digest/sha1'
require 'unicode'

class WhatLanguage
  VERSION = '1.0.3'
  
  HASHER = lambda { |item| Digest::SHA1.digest(item.downcase.strip).unpack("VV") }
  
  BITFIELD_WIDTH = 2_000_000
  
  @@data = {}
  
  def initialize(options = {})
    languages_folder = File.join(File.dirname(__FILE__), "..", "lang")
    Dir.entries(languages_folder).grep(/\.lang/).each do |lang|
      @@data[lang[/\w+/].to_sym] ||= BloominSimple.from_dump(File.new(File.join(languages_folder, lang), 'rb').read, &HASHER)
    end
  end

  def process_text(text)
    text.split(/[\,\.\?\!\:\; ]/).reject(&:empty?).map do |word|
      Unicode::downcase word
    end.uniq.each_with_object(Hash.new(0)) do |word, results|
      @@data.keys.each do |lang|
        results[lang] += 1 if @@data[lang].includes? word
      end
    end
  end

  def language(text)
    process_text(text).max { |a,b| a[1] <=> b[1] }.first rescue nil
  end
  
  def self.filter_from_dictionary(filename)
    bf = BloominSimple.new(BITFIELD_WIDTH, &HASHER)
    File.open(filename).each { |word| bf.add(word) }
    bf
  end
end

class String
  def language
    WhatLanguage.new(:all).language(self)
  end
end
