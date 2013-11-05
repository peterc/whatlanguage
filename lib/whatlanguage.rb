require 'whatlanguage/bloominsimple'
require 'whatlanguage/bitfield'
require 'digest/sha1'

class WhatLanguage  
  HASHER = lambda { |item| Digest::SHA1.digest(item.downcase.strip).unpack("VV") }
  
  BITFIELD_WIDTH = 2_000_000
  
  @@data = {}
  
  def initialize(*selection)
    @selection = (selection.empty?) ? [:all] : selection
    languages_folder = File.join(File.dirname(__FILE__), "..", "lang")
    Dir.entries(languages_folder).grep(/\.lang/).each do |lang|
      @@data[lang[/\w+/].to_sym] ||= BloominSimple.from_dump(File.new(File.join(languages_folder, lang), 'rb').read, &HASHER)
    end
  end

  def languages
    @languages ||=
      begin
        if @selection.include?(:all)
          languages = @@data.keys
        else
          languages = @@data.keys & @selection  # intersection
        end
      end
  end
  
  # Very inefficient method for now.. but still beats the non-Bloom alternatives.
  # Change to better bit comparison technique later..
  def process_text(text, options = {})
    options = {
      exit_early: true
    }.merge options

    results = Hash.new(0)
    it = 0
    text.downcase.split.each do |word|
      it += 1

      languages.each do |lang|
        results[lang] += 1 if @@data[lang].includes?(word)
      end

      # Every now and then check to see if we have a really convincing result.. if so, exit early.
      if options[:exit_early] && it % 4 == 0 && results.size > 1
        top_results = results.sort_by{|a,b| -b}[0..1]
        
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
