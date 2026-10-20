# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/reference_detector"

class PreprocessingTest < Minitest::Test
  def test_preprocessing_matches_original_for_unicode_and_boundaries
    original = WhatLanguageTestSupport::ReferenceDetector.new
    optimized = WhatLanguage.new
    samples = ["", "a", "ab", "abc", "abcd", " a ", "a  b", "  a   b  ",
               "A1b2C", "\0a\tb\r\nc", "a\u0301\u0302", "\u0301a",
               "ΟΣ ΟΣΑ ος", "İstanbul", "漢字あア abc", "𐐀𐐨 hello",
               "😀๑٢— a 😀 b", "a" * 10_000, (0..127).map(&:chr).join]
    random = Random.new(294041)
    alphabet = "abXYéİßΣςЖяאבابتथकअሀለ漢字あア한글𐐀𐐨\u0301\u0302 😀_—12\n".chars
    [0, 1, 2, 3, 9, 10, 49, 50, 300, 600, 2000].each do |length|
      10.times { samples << Array.new(length) { alphabet.sample(random: random) }.join }
      samples << Array.new(length) { random.rand(128).chr }.join
    end
    samples.each do |text|
      normalized = original.send(:normalize_text, text)
      label = text[0, 60].inspect
      expected_script = original.send(:detect_script, normalized)
      expected_count = original.send(:significant_char_count, normalized)
      assert_equal [expected_script, expected_count],
                   optimized.send(:script_and_letter_count, normalized), label
      assert_equal original.send(:trigram_positions, normalized),
                   optimized.send(:trigram_positions, normalized), label
    end
  end

  def test_winner_only_apis_preserve_ties_and_empty_results
    detector = WhatLanguage.new
    ["", "hi", "x" * 20, "qzxv " * 100, "hello world", "こんにちは"].each do |text|
      result = detector.detect(text)
      assert_equal [result&.language], [detector.language(text)], text
      assert_equal [result&.iso], [detector.language_iso(text)], text
    end
  end

  def test_candidate_cache_tracks_mutable_language_lists
    original = WhatLanguageTestSupport::ReferenceDetector.new(only: [:english, :german])
    optimized = WhatLanguage.new(only: [:english, :german])
    text = "This is a longer English sentence with enough common words."

    [[:english, :german], [:german], [], [:french, :english], [:english, :german]].each do |names|
      original.languages.replace(names)
      optimized.languages.replace(names)
      assert_equal original.score_hash(text).to_a, optimized.score_hash(text).to_a
      assert_equal [original.detect(text)&.to_h], [optimized.detect(text)&.to_h]
    end
  end
end
