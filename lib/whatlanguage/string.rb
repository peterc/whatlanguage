require 'whatlanguage'

class String
  def language
    WhatLanguage.new(:all).language(self)
  end

  def language_iso
    WhatLanguage.new(:all).language_iso(self)
  end
end
