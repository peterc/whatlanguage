# frozen_string_literal: true

require_relative "test_helper"

class WhatLanguageTest < Minitest::Test
  def setup
    @wl = WhatLanguage.new
  end

  def test_hebrew
    # Hebrew and Yiddish share a script; on a 3-word fragment they are not
    # separable, but at the documented ~10+ word length Hebrew resolves cleanly.
    assert_equal :hebrew, @wl.language("עברית היא שפה שמית שמדוברת בעיקר בישראל, והיא השפה הרשמית של המדינה ומדברים בה מיליוני אנשים מדי יום.")
  end

  def test_halfwidth_hangul
    assert_equal :korean, @wl.language("ﾡﾢﾣ")
  end

  def test_halfwidth_katakana
    assert_equal :japanese, @wl.language("ｶﾀｶﾅ")
  end

  def test_fullwidth_latin
    assert_equal :english, @wl.language("Ｔｈｉｓ ｉｓ ａ ｔｅｓｔ")
  end

  def test_norwegian
    # Known limitation: Norwegian Bokmål and Danish are near-identical in
    # writing, and the dataset further splits Norwegian across Bokmål and
    # Nynorsk. Against the full language set, Norwegian text resolves to Danish
    # by a sub-0.5% margin even at sentence length. Restricting the candidate
    # set makes it detectable again.
    selective = WhatLanguage.new(only: [:norwegian, :swedish, :finnish, :english])
    assert_equal :norwegian, selective.language("Norsk er et nordgermansk språk som snakkes av rundt fem millioner mennesker, hovedsakelig i Norge.")
  end

  def test_japanese_combines_han_and_kana
    ["東京都に住む", "日本語の文章です", "東京タワー", "漢字漢字あア"].each do |text|
      assert_equal :japanese, @wl.language(text), text
    end
  end

  def test_kana_does_not_override_dominant_unrelated_script
    text = "This is a longer English sentence with enough common words あ"
    assert_equal :english, @wl.language(text)
  end

  def test_han_without_kana_still_resolves_to_chinese
    assert_equal :chinese, @wl.language("中文")
    assert_equal :chinese, @wl.language("\u{20000}")
  end

  def test_japanese_script_handling_respects_selection
    assert_equal :japanese, WhatLanguage.new(only: :japanese).language("日本語の文章です")
    assert_nil WhatLanguage.new(only: :chinese).language("日本語の文章です")
  end

  def test_georgian_uppercase
    assert_equal :georgian, @wl.language("ᲒᲐᲛᲐᲠᲯᲝᲑᲐ")
  end

  def test_greek_extended_letters
    assert_equal :greek, @wl.language("ἀἁἂἃ")
  end

  def test_non_letters_do_not_identify_a_language
    ["๑๒๓๔๕", "١٢٣٤٥", "१२३४५", "©®±×÷" * 3, "😀" * 12,
     "。、！？", "\u0301" * 12, "ー"].each do |text|
      assert_nil @wl.language(text), text
      assert_nil WhatLanguage.new(min_chars: 0).language(text), text
    end
  end

  def test_non_letters_do_not_pad_short_text
    ["😀", "๑", "©", "—", "\u0301"].each do |padding|
      assert_nil @wl.language("hi" + padding * 12), padding
    end
  end

  def test_unicode_separators_do_not_pollute_trigrams
    words = %w[this is a longer English sentence with enough common words]
    expected = @wl.score_hash(words.join(" "))
    ["—", "😀", "١", "。"].each do |separator|
      assert_equal expected, @wl.score_hash(words.join(separator)), separator
    end
  end

  def test_decomposed_accents_match_precomposed_text
    text = "O relatório apresenta propostas para melhorar a educação e a saúde."
    assert_equal @wl.score_hash(text), @wl.score_hash(text.unicode_normalize(:nfd))
  end

  def test_nothing
    assert_nil @wl.language("")
  end

  def test_something
    assert_nil @wl.language("test")
  end

  def test_min_chars_can_be_lowered
    refute_nil WhatLanguage.new(min_chars: 0).language("test")
  end

  def test_score_hash
    assert_kind_of Hash, @wl.score_hash("this is a test")
  end

  def test_compatibility_score_aliases
    assert_equal @wl.score_hash("this is a test"), @wl.scores("this is a test")
    assert_equal @wl.score_hash("this is a test"), @wl.process_text("this is a test")
  end

  def test_ranked
    ranked = @wl.ranked("this is a longer English sentence with enough common words")

    assert_kind_of Array, ranked
    assert_equal :english, ranked.first.first
  end

  def test_detect
    result = @wl.detect("this is a longer English sentence with enough common words")

    assert_equal :english, result.language
    assert_equal :en, result.iso
    assert_kind_of Integer, result.score
    assert_kind_of Array, result.ranked
    assert_equal result.ranked, result.scores
  end

  def test_language_selection
    selective_wl = WhatLanguage.new(only: [:german, :english])
    assert_equal :german, selective_wl.language("der die das und eine deutsche Sprache")
  end

  def test_language_selection_accepts_single_language
    selective_wl = WhatLanguage.new(only: :english)
    assert_equal [:english], selective_wl.languages
  end

  def test_language_selection_rejects_unknown_language
    error = assert_raises(ArgumentError) { WhatLanguage.new(only: :klingon) }
    assert_match(/:klingon/, error.message)
  end

  def test_language_selection_accepts_legacy_alias
    assert_equal [:chinese], WhatLanguage.new(only: :pinyin).languages
  end

  def test_legacy_positional_language_selection
    selective_wl = WhatLanguage.new(:german, :english)
    assert_equal [:english, :german], selective_wl.languages.sort
  end

  def test_language_selection_empty
    selective_wl = WhatLanguage.new
    assert_equal :russian, selective_wl.language("Все новости в хронологическом порядке")
  end

  def test_language_selection_mixed
    selective_wl = WhatLanguage.new(:german, :all, :english)
    assert_equal :russian, selective_wl.language("Все новости в хронологическом порядке")
  end

  def test_class_level_api
    text = "this is a longer English sentence with enough common words"

    assert_equal :english, WhatLanguage.language(text)
    assert_equal :en, WhatLanguage.language_iso(text)
    assert_equal :english, WhatLanguage.detect(text).language
    assert_equal :english, WhatLanguage.ranked(text).first.first
    assert_kind_of Hash, WhatLanguage.score_hash(text)
  end

  def test_class_level_languages
    assert_includes WhatLanguage.languages, :english
    assert_equal WhatLanguage.languages, WhatLanguage.new.languages
  end

  def test_casing_conversion
    assert_equal @wl.language("âncora cor âmbar"), @wl.language("ÂNCORA COR ÂMBAR")
  end
end
