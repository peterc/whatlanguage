# frozen_string_literal: true

require 'json'
require_relative 'whatlanguage/languages'
require_relative 'whatlanguage/version'

class WhatLanguage
  MAX_TRIGRAM_DISTANCE = 300
  MAX_TOTAL_DISTANCE   = MAX_TRIGRAM_DISTANCE * MAX_TRIGRAM_DISTANCE # 90_000
  TEXT_TRIGRAMS_SIZE   = 600
  DEFAULT_MIN_CHARS    = 10
  SHORT_TEXT_PREFERENCES = %i[english chinese hindi spanish french].freeze
  SHORT_TEXT_BONUS = 600
  SHORT_TEXT_FADE_CHARS = 50

  Result = Struct.new(:language, :iso, :score, :ranked, keyword_init: true) do
    alias scores ranked
  end

  # Scripts that resolve to a single supported language from their letters.
  # (Hiragana and Katakana both indicate Japanese.) Scripts NOT listed here but
  # present in the trigram dataset are disambiguated statistically instead.
  DETERMINISTIC = {
    'Mandarin'  => 'cmn', 'Bengali' => 'ben', 'Hangul'   => 'kor',
    'Georgian'  => 'kat', 'Greek'   => 'ell', 'Kannada'  => 'kan',
    'Tamil'     => 'tam', 'Thai'    => 'tha', 'Gujarati' => 'guj',
    'Gurmukhi'  => 'pan', 'Telugu'  => 'tel', 'Malayalam'=> 'mal',
    'Oriya'     => 'ori', 'Myanmar' => 'mya', 'Sinhala'  => 'sin',
    'Khmer'     => 'khm', 'Armenian'=> 'hye', 'Hiragana' => 'jpn',
    'Katakana'  => 'jpn'
  }.freeze

  # Unicode script properties include letters outside the original BMP blocks.
  # Keep the model's historical "Mandarin" key for the Han script.
  SCRIPT_PATTERNS = %w[
    Latin Cyrillic Arabic Han Devanagari Hebrew Ethiopic Georgian Bengali
    Hangul Hiragana Katakana Greek Kannada Tamil Thai Gujarati Gurmukhi
    Telugu Malayalam Oriya Myanmar Sinhala Khmer Armenian
  ].map { |script| [script == 'Han' ? 'Mandarin' : script, Regexp.new("\\p{#{script}}")] }.freeze

  # ISO 639-1 (with 639-3 fallback) lookup by language-name symbol, plus the
  # historical nil => nil entry. Internal; kept for backward compatibility.
  ISO_CODES = CODE_INFO.each_with_object(nil => nil) do |(_code, (name, iso)), h|
    h[name] = iso
  end.freeze

  NAME_TO_CODE = CODE_INFO.each_with_object({}) do |(code, (name, _iso)), h|
    h[name] ||= code
  end.freeze

  private_constant :MAX_TRIGRAM_DISTANCE, :MAX_TOTAL_DISTANCE, :TEXT_TRIGRAMS_SIZE,
                   :DEFAULT_MIN_CHARS, :DETERMINISTIC, :SCRIPT_PATTERNS, :ISO_CODES,
                   :NAME_TO_CODE, :SHORT_TEXT_PREFERENCES, :SHORT_TEXT_BONUS,
                   :SHORT_TEXT_FADE_CHARS

  class << self
    def detect(text)
      default_detector.detect(text)
    end

    def language(text)
      default_detector.language(text)
    end

    def language_iso(text)
      default_detector.language_iso(text)
    end

    def ranked(text)
      default_detector.ranked(text)
    end

    def score_hash(text)
      default_detector.score_hash(text)
    end

    alias scores score_hash
    alias process_text score_hash

    def languages
      NAME_TO_CODE.keys
    end

    # script name => [[code, [trigram, ...]], ...], loaded once and memoized.
    def profiles
      @profiles ||= JSON.parse(File.read(File.join(__dir__, 'whatlanguage', 'trigrams.json')))
                        .transform_values { |langs| langs.map { |code, str| [code, str.split('|')] } }
    end

    private

    def default_detector
      @default_detector ||= new
    end
  end

  def initialize(*selection, only: nil, min_chars: DEFAULT_MIN_CHARS)
    @selection = Array(only || (selection.empty? ? [:all] : selection))
    validate_selection!
    @min_chars = min_chars
  end

  # Language-name symbols this instance scores against: every supported language
  # for :all, otherwise the requested selection intersected with the supported
  # set (legacy aliases such as :pinyin resolved to their modern names).
  def languages
    @languages ||=
      if @selection.include?(:all)
        self.class.languages
      else
        wanted = @selection.map { |s| NAME_ALIASES.fetch(s, s) }
        self.class.languages & wanted
      end
  end

  # Per-language scores for the text (higher = more likely). Languages outside
  # the current selection, or not under the detected script, are absent; the
  # hash defaults to 0. Only the relative ranking is meaningful.
  def score_hash(text)
    results = Hash.new(0)
    text = normalize_text(text)
    script = detect_script(text)
    return results unless script

    if (code = DETERMINISTIC[script])
      name = CODE_INFO[code].first
      results[name] = MAX_TOTAL_DISTANCE if allowed?(name)
      return results
    end

    candidates = self.class.profiles[script]
    return results unless candidates
    char_count = significant_char_count(text)
    return results if char_count < @min_chars

    bonus = short_text_bonus(char_count)
    positions = trigram_positions(text)
    candidates.each do |code, trigrams|
      name = CODE_INFO[code].first
      next unless allowed?(name)

      results[name] = MAX_TOTAL_DISTANCE - distance(trigrams, positions)
      results[name] += bonus if SHORT_TEXT_PREFERENCES.include?(name)
    end
    results
  end

  alias scores score_hash
  alias process_text score_hash

  # Per-language scores as an array sorted from most likely to least likely.
  def ranked(text)
    score_hash(text).sort_by { |_name, score| -score }
  end

  # Detection result with the winning language, ISO code, winning score, and
  # full ranked scores. Returns nil when the text is too short or unrecognized.
  def detect(text)
    ranked_scores = ranked(text)
    return nil if ranked_scores.empty?

    name, score = ranked_scores.first
    Result.new(language: name, iso: ISO_CODES[name], score: score, ranked: ranked_scores)
  end

  # Most likely language as a name symbol, or nil when no language is detected.
  def language(text)
    detect(text)&.language
  end

  # Most likely language as an ISO 639-1 symbol (639-3 fallback), or nil.
  def language_iso(text)
    detect(text)&.iso
  end

  private

  # A small fixed prior for widely spoken languages: full strength through ten
  # letters, fading linearly to zero at fifty. These are ranking points, not
  # probabilities. Script routing and the caller's candidate selection still win.
  def short_text_bonus(char_count)
    remaining = (SHORT_TEXT_FADE_CHARS - char_count).clamp(0, SHORT_TEXT_FADE_CHARS - DEFAULT_MIN_CHARS)
    SHORT_TEXT_BONUS * remaining / (SHORT_TEXT_FADE_CHARS - DEFAULT_MIN_CHARS)
  end

  def normalize_text(text)
    text.to_s.unicode_normalize(:nfkc)
  end

  def allowed?(name)
    @selection.include?(:all) || languages.include?(name)
  end

  def validate_selection!
    requested = @selection.reject { |name| name == :all }
    unknown = requested.reject { |name| self.class.languages.include?(NAME_ALIASES.fetch(name, name)) }
    return if unknown.empty?

    raise ArgumentError, "Unknown language selection: #{unknown.map(&:inspect).join(', ')}"
  end

  def significant_char_count(text)
    text.each_char.count { |ch| /\p{L}/.match?(ch) }
  end

  # Dominant Unicode script of the text, or nil if it has no script characters.
  def detect_script(text)
    counts = Hash.new(0)
    text.each_char do |ch|
      next unless /\p{L}/.match?(ch)

      SCRIPT_PATTERNS.each do |name, pattern|
        if pattern.match?(ch)
          counts[name] += 1
          break
        end
      end
    end
    return nil if counts.empty?

    # Japanese uses Han, Hiragana, and Katakana together. Combine their votes
    # when kana is present, but still let a dominant unrelated script win.
    if counts['Hiragana'] + counts['Katakana'] > 0
      japanese = counts['Mandarin'] + counts['Hiragana'] + counts['Katakana']
      counts.delete('Mandarin')
      counts.delete('Katakana')
      counts['Hiragana'] = japanese
    end

    counts.max_by { |_name, n| n }.first
  end

  # Text trigrams ranked by descending frequency, mapped to their rank index.
  # Non-letter/mark characters become spaces. Preserve combining marks used
  # by the profiles; bound the stream by spaces and ignore repeated spaces.
  def trigram_positions(text)
    chars = text.downcase.each_char.map { |c| /[\p{L}\p{M}]/.match?(c) ? c : ' ' }
    return {} if chars.empty?

    occurrences = Hash.new(0)
    c1 = ' '
    c2 = chars[0]
    (chars[1..] + [' ']).each do |c3|
      occurrences[c1 + c2 + c3] += 1 unless c2 == ' ' && (c1 == ' ' || c3 == ' ')
      c1 = c2
      c2 = c3
    end

    ranked = occurrences.to_a.sort { |a, b| [b[1], b[0]] <=> [a[1], a[0]] }.first(TEXT_TRIGRAMS_SIZE)
    positions = {}
    ranked.each_with_index { |(trigram, _count), i| positions[trigram] = i }
    positions
  end

  # Out-of-place distance between a language's ordered trigram profile and the
  # text's ranked trigrams. Lower means a closer match.
  def distance(profile, positions)
    total = 0
    profile.each_with_index do |trigram, i|
      pos = positions[trigram]
      total += pos ? (pos - i).abs : MAX_TRIGRAM_DISTANCE
    end

    count = positions.size
    total -= (MAX_TRIGRAM_DISTANCE - count) * MAX_TRIGRAM_DISTANCE if MAX_TRIGRAM_DISTANCE > count
    total.clamp(0, MAX_TOTAL_DISTANCE)
  end
end
