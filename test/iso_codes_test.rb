# frozen_string_literal: true

require_relative "test_helper"

class IsoCodesTest < Minitest::Test
  def test_iso_codes_through_public_apis_across_scripts
    samples = [
      [:english, :en, "This is a longer English sentence with enough common words"],
      [:german, :de, "Die Stadt plant neue Investitionen in den öffentlichen Verkehr"],
      [:portuguese, :pt, "Que linguagem é essa? É uma pergunta sobre a língua portuguesa."],
      [:chinese, :zh, "中文"],
      [:japanese, :ja, "日本語の文章です"],
      [:korean, :ko, "한국어"],
      [:greek, :el, "Ελληνικά"]
    ]
    detector = WhatLanguage.new

    samples.each do |language, iso, text|
      [detector, WhatLanguage].each do |api|
        result = api.detect(text)
        refute_nil result, language.to_s
        assert_equal language, result.language
        assert_equal iso, result.iso, language.to_s
        assert_equal iso, api.language_iso(text), language.to_s
      end
    end
  end

  def test_swahili_iso_code_through_public_apis
    text = "Habari za asubuhi. Leo tunakwenda sokoni kununua matunda, mboga na mkate. " \
           "Mama yangu anapenda kupika chakula kizuri kwa familia yote jioni."
    detector = WhatLanguage.new

    [detector, WhatLanguage].each do |api|
      result = api.detect(text)
      assert_equal :swahili, result.language
      assert_equal :sw, result.iso
      assert_equal :sw, api.language_iso(text)
    end
  end

  def test_selected_languages_use_cldr_macrolanguage_aliases
    expected = {
      swahili: :sw, central_aymara: :ay, central_kanuri: :kr,
      cusco_quechua: :qu, halh_mongolian: :mn, koongo: :kg,
      logudorese_sardinian: :sc, northern_uzbek: :uz, tosk_albanian: :sq,
      chinese: :zh, farsi: :fa, uzbek: :uz
    }
    assert_selected_iso_codes(expected)
  end

  def test_individual_languages_without_cldr_aliases_keep_their_codes
    assert_selected_iso_codes(
      ayacucho_quechua: :quy, chimborazo_highland_quichua: :qug,
      komi_permyak: :koi, minangkabau: :min
    )
  end

  def test_languages_without_two_letter_codes_use_three_letter_fallbacks
    assert_selected_iso_codes(
      achinese: :ace, cebuano: :ceb, hiligaynon: :hil,
      low_german: :nds, tok_pisin: :tpi
    )
  end

  def test_historical_norwegian_code_and_nynorsk_remain_distinct
    assert_selected_iso_codes(norwegian: :no, norwegian_nynorsk: :nn)
  end

  def test_legacy_chinese_selection_aliases_return_the_same_iso_code
    [:chinese, :mandarin, :pinyin].each do |selection|
      detector = WhatLanguage.new(only: selection)
      result = detector.detect("中文")
      assert_equal :chinese, result.language
      assert_equal :zh, result.iso
      assert_equal :zh, detector.language_iso("中文")
    end
  end

  def test_undetermined_input_has_no_iso_code
    [WhatLanguage.new, WhatLanguage].each do |api|
      ["", "hi", "1234567890", "😀" * 12].each do |text|
        assert_nil api.detect(text), text.inspect
        assert_nil api.language_iso(text), text.inspect
      end
    end
  end

  def test_excluded_language_has_no_iso_code
    detector = WhatLanguage.new(only: :english)
    assert_nil detector.detect("日本語の文章です")
    assert_nil detector.language_iso("日本語の文章です")
  end

  private

  def assert_selected_iso_codes(expected)
    # Restrict candidates to test output codes independently of model accuracy.
    # Include each relevant script so its profile is exercised.
    texts = ["This is a sentence with enough letters for detection.",
             "Это предложение содержит достаточно букв для определения языка.",
             "این یک جمله برای تشخیص زبان است", "中文"]
    expected.each do |language, iso|
      detector = WhatLanguage.new(only: language)
      result = texts.filter_map { |text| detector.detect(text) }.first
      refute_nil result, language.to_s
      assert_equal language, result.language
      assert_equal iso, result.iso, language.to_s
    end
  end
end
