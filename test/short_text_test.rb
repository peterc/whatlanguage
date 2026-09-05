# frozen_string_literal: true

require_relative "test_helper"

class ShortTextTest < Minitest::Test
  def setup
    @detector = WhatLanguage.new
  end

  def test_short_greetings_and_requests
    { "hello there" => :english,
      "thank you very much" => :english,
      "bonjour à tous" => :french }.each do |text, expected|
      assert_equal expected, @detector.language(text), text
    end
  end

  def test_fragments_below_minimum_remain_undetermined
    ["hello", "bonjour", "how are you", "por favor", "das ist gut",
     "buona sera", "привет мир", "नमस्ते दुनिया"].each do |text|
      assert_nil @detector.detect(text), text
      assert_empty @detector.ranked(text), text
    end
  end

  def test_minimum_boundary_counts_letters_not_spaces
    assert_nil @detector.language("hello ther") # Nine letters.
    assert_equal :english, @detector.language("hello there") # Ten letters.
    assert_nil WhatLanguage.new(min_chars: 11).language("hello there")
  end

  def test_case_width_and_surrounding_noise_preserve_short_text_scores
    expected = @detector.score_hash("hello world")
    ["HELLO WORLD", "ＨＥＬＬＯ ＷＯＲＬＤ",
     "😀 hello world! ๑๒๓"].each do |text|
      assert_equal expected, @detector.score_hash(text), text
    end
  end

  def test_extra_whitespace_preserves_short_text_detection
    assert_equal :english, @detector.language("  hello   world  ")
  end

  def test_non_preferred_languages_can_win_short_texts
    { "Das ist eine deutsche Sprache" => :german,
      "O português é uma língua" => :portuguese,
      "Dit is een Nederlandse zin" => :dutch,
      "Türkçe bir cümle yazıyorum" => :turkish }.each do |text, expected|
      assert_equal expected, @detector.language(text), text
    end
  end

  def test_short_distinctive_scripts_do_not_need_ten_letters
    { "你好" => :chinese, "こんにちは" => :japanese,
      "안녕하세요" => :korean, "สวัสดี" => :thai }.each do |text, expected|
      assert_equal expected, @detector.language(text), text
    end
  end

  def test_short_result_is_consistent_across_public_apis
    text = "hello world"
    result = @detector.detect(text)
    assert_equal :english, result.language
    assert_equal :en, result.iso
    assert_equal [:english, result.score], result.ranked.first
    assert_equal result.ranked, WhatLanguage.ranked(text)
    assert_equal result.score, WhatLanguage.score_hash(text)[:english]
    assert_equal :en, WhatLanguage.language_iso(text)
  end

  def test_excluding_preferred_languages_does_not_add_them_back
    detector = WhatLanguage.new(only: [:german, :dutch])
    assert_equal [:dutch, :german], detector.ranked("hello world").map(&:first).sort
    assert_nil WhatLanguage.new(only: :english).detect("你好")
  end
end
