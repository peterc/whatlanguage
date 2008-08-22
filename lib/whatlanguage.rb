require File.join(File.dirname(__FILE__), 'bloominsimple')
require 'digest/sha1'

class WhatLanguage
  VERSION = '1.0.0'
  
  HASHER = lambda { |item| Digest::SHA1.digest(item.downcase.strip).unpack("VV") }
  
  BITFIELD_WIDTH = 2_000_000
  
  @@data = {}
  
  def initialize(options)
    languages_folder = File.join(File.dirname(__FILE__), "..", "lang")
    Dir.entries(languages_folder).grep(/\.lang/).each do |lang|
      @@data[lang[/\w+/].to_sym] ||= BloominSimple.from_dump(File.read(File.join(languages_folder, lang)), &HASHER)
    end
  end
  
  # Very inefficient method for now.. but still beats the non-Bloom alternatives.
  # Change to better bit comparison technique later..
  def process_text(text)
    results = Hash.new(0)
    it = 0
    text.split.collect {|a| a.downcase }.each do |word|
      it += 1
      @@data.keys.each do |lang|
        results[lang] += 1 if @@data[lang].includes?(word)
      end
      
      # Every now and then check to see if we have a really convincing result.. if so, exit early.
      if it % 4 == 0 && results.size > 1
        top_results = results.sort_by{|a,b| b}.reverse[0..1]
        
        # Next line may need some tweaking one day..
        break if top_results[0][1] > 4 && ((top_results[0][1] > top_results[1][1] * 2) || (top_results[0][1] - top_results[1][1] > 25))
      end
      
      #break if it > 100
    end
    results
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