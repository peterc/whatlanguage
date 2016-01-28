# encoding: utf-8
require "test/unit"

# not a dependency
begin
  require 'unicode_utils'
rescue LoadError
end

require 'whatlanguage/string'

class TestWhatLanguage < Test::Unit::TestCase
  def setup
    @wl = WhatLanguage.new(:all)
  end

  def test_string_method
    assert_equal :english, "This is a test".language
  end

  def test_string_iso_method
    assert_equal :en, "this is a test".language_iso
  end

  def test_arabic
    assert_equal :arabic, @wl.language("اللغة التي هي هذه؟")
  end

  def test_dutch
    assert_equal :dutch, @wl.language("Als hadden geweest is, is hebben te laat.")
  end

  def test_farsi
    assert_equal :farsi, @wl.language("وقتی مادرم به من آموخت که به آواز خواندن.")
  end

  def test_finnish
    assert_equal :finnish, @wl.language("Mitä kieltä tämä on?")
  end

  def test_french
    assert_equal :french, @wl.language("Bonjour, je m'appelle Sandrine. Voila mon chat.")
  end

  def test_german
    assert_equal :german, @wl.language("Welche Sprache ist das?")
  end

  def test_greek
    assert_equal :greek, @wl.language("Ποια γλώσσα είναι αυτή;")
  end

  def test_hebrew
    assert_equal :hebrew, @wl.language("באיזו שפה זה?")
  end

  def test_hungarian
    assert_equal :hungarian, @wl.language("Milyen nyelv ez?")
  end

  def test_italian
    assert_equal :italian, @wl.language("Roma, capitale dell'impero romano, è stata per secoli il centro politico e culturale della civiltà occidentale.")
  end

  def test_korean
    assert_equal :korean, @wl.language("이 어떤 언어인가?")
  end

  def test_norwegian
    assert_equal :norwegian, @wl.language("Hvilket språk er dette?")
  end

  def test_polish
    assert_equal :polish, @wl.language("W jakim języku to jest?")
  end

  def test_portuguese
    assert_equal :portuguese, @wl.language("Que linguagem é essa?")
  end

  def test_russian
    assert_equal :russian, @wl.language("Все новости в хронологическом порядке")
  end

  def test_spanish
    assert_equal :spanish, @wl.language("La palabra mezquita se usa en español para referirse a todo tipo de edificios dedicados.")
  end

  def test_swedish
    assert_equal :swedish, @wl.language("Vilket språk är detta?")
  end

  def test_danish
    assert_equal :danish, @wl.language("Dansk er et nord-germansk sprog af den østnordiske (kontinentale) gruppe, der tales af ca. seks millioner mennesker.")
  end

  def test_nothing
    assert_nil @wl.language("")
  end

  def test_something
    assert_not_nil @wl.language("test")
  end

  def test_processor
    assert_kind_of Hash, @wl.process_text("this is a test")
  end

  def test_language_selection
    selective_wl = WhatLanguage.new(:german, :english)
    assert_equal :german, selective_wl.language("der die das")
  end

  def test_language_selection_empty
    selective_wl = WhatLanguage.new()
    assert_equal :russian, selective_wl.language("Все новости в хронологическом порядке")
  end

  def test_language_selection_mixed
    selective_wl = WhatLanguage.new(:german, :all, :english)
    assert_equal :russian, selective_wl.language("Все новости в хронологическом порядке")
  end

  if defined? UnicodeUtils
    def test_casing_conversion
      assert_equal "âncora cor âmbar".language, "ÂNCORA COR ÂMBAR".language
    end
  end
end
