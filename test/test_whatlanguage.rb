# encoding: utf-8
require "test/unit"

require 'whatlanguage'

class TestWhatLanguage < Test::Unit::TestCase
  def setup
    @wl = WhatLanguage.new(:all)
  end
  
  def test_string_method
    assert_equal :english, "This is a test".language
  end

  def test_dutch
    assert_equal :dutch, @wl.language("Als hadden geweest is, is hebben te laat.")
  end

  def test_french
    assert_equal :french, @wl.language("Bonjour, je m'appelle Sandrine. Voila ma chatte.")
  end
  
  def test_spanish
    assert_equal :spanish, @wl.language("La palabra mezquita se usa en español para referirse a todo tipo de edificios dedicados.")
  end

  def test_swedish
    assert_equal :swedish, @wl.language("Den spanska räven rev en annan räv alldeles lagom.")
  end

  def test_russian
    assert_equal :russian, @wl.language("Все новости в хронологическом порядке")
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

  def test_italian
    assert_equal :italian, @wl.language("Roma, capitale dell'impero romano, è stata per secoli il centro politico e culturale della civiltà occidentale.")
  end

end
