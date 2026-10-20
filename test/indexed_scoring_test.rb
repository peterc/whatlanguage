# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/reference_detector"

class IndexedScoringTest < Minitest::Test
  def test_public_results_match_original_scorer
    samples = JSON.parse(File.read(File.join(__dir__, "fixtures/accuracy_samples.json")))
                  .map { |entry| entry.fetch("sample") }
    samples.concat([
      "", "12378178312", "j3j843j843j8", "x" * 20, "a" * 100,
      "hello world", "bonjour", "test", "中文", "漢字漢字あア",
      "😀 HELLO WORLD! ๑๒๓", "Ｔｈｉｓ ｉｓ ａ ｔｅｓｔ",
      "O relatório apresenta propostas para melhorar a educação.".unicode_normalize(:nfd),
      "አማርኛ ትግርኛ " * 10,
      "This is a longer English sentence with enough common words. " * 200
    ])
    random = Random.new(9507037)
    [
      ("a".."z").to_a,
      "абвгдежзийклмнопрстуфхцчшщыэюя".chars,
      "ابتثجحخدذرزسشصضطظعغفقكلمنهوي".chars,
      "अआइईउएकखगघचजटडतदनपबमयरलवसह".chars,
      "אבגדהוזחטיכלמנסעפצקרשת".chars,
      "ሀለሐመሠረሰሸቀበተቸኀነኘአከኸወዐዘየደገጠፈፐ".chars
    ].each do |alphabet|
      [9, 10, 30, 49, 50, 300, 1200].each do |length|
        samples << Array.new(length) { (alphabet + [" ", "3", "😀"]).sample(random: random) }.join
      end
    end

    [
      {}, { min_chars: 0 }, { min_chars: 50 },
      { only: [:english, :german, :french] }, { only: :english },
      { only: [] }, { only: [:russian, :ukrainian] },
      { only: [:hebrew, :yiddish] }, { only: :pinyin },
      { only: [:english, :all] }
    ].each do |options|
      original = WhatLanguageTestSupport::ReferenceDetector.new(**options)
      indexed = WhatLanguage.new(**options)
      samples.each do |text|
        label = "#{options.inspect}: #{text[0, 80].inspect}"
        expected = original.score_hash(text)
        actual = indexed.score_hash(text)
        assert_equal expected.to_a, actual.to_a, label # Includes insertion/tie order.
        assert_equal expected.default, actual.default, label
        assert_equal original.ranked(text), indexed.ranked(text), label
        assert_equal [original.detect(text)&.to_h], [indexed.detect(text)&.to_h], label
        assert_equal [original.language(text)], [indexed.language(text)], label
        assert_equal [original.language_iso(text)], [indexed.language_iso(text)], label
      end
    end
  end

  def test_indexed_arithmetic_matches_original_at_rank_boundaries
    indexed = WhatLanguage.new
    original = WhatLanguageTestSupport::ReferenceDetector.new
    random = Random.new(300)

    WhatLanguage.profiles.each do |script, candidates|
      vocabulary = candidates.flat_map { |_code, trigrams| trigrams }.uniq
      indexed.send(:indexed_distances, script, {}) # First call may use the direct scan.
      [0, 1, 299, 300, 301, 599, 600].each do |count|
        # Exercise both dense overlap and mostly missing trigrams, with actual
        # model trigrams at ranks above 300 as well as below the boundary.
        [vocabulary.shuffle(random: random),
         Array.new(count) { |i| "missing-#{i}" } + vocabulary].each do |trigrams|
          positions = trigrams.first(count).each_with_index.to_h
          expected = candidates.map do |_code, profile|
            original.send(:reference_distance, profile, positions)
          end
          assert_equal expected, indexed.send(:indexed_distances, script, positions),
                       "#{script}, #{count} trigrams"
        end
      end
    end
  end

  def test_index_is_built_only_after_a_script_is_reused_and_shared_by_instances
    detector_class = Class.new(WhatLanguage)
    detector = detector_class.new
    text = "This is a longer English sentence with enough common words."
    expected = WhatLanguageTestSupport::ReferenceDetector.new.score_hash(text)

    assert_nil detector.detect("hi")
    assert_equal :japanese, detector.language("こんにちは")
    assert_equal :english, detector_class.new(only: :english).language(text)
    refute detector_class.instance_variable_defined?(:@profile_indexes)

    assert_equal expected, detector.score_hash(text)
    assert_nil detector_class.instance_variable_get(:@profile_indexes).fetch("Latin")

    assert_equal expected, detector.score_hash(text)
    index = detector_class.instance_variable_get(:@profile_indexes).fetch("Latin")
    refute_nil index
    assert index.frozen?
    assert_equal expected, detector_class.new.score_hash(text)
    assert_same index, detector_class.instance_variable_get(:@profile_indexes).fetch("Latin")
    assert_equal ["Latin"], detector_class.instance_variable_get(:@profile_indexes).keys
  end
end
