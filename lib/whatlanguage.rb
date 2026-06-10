# frozen_string_literal: true

require 'json'
require_relative 'whatlanguage/languages'
require_relative 'whatlanguage/version'

class WhatLanguage
  MAX_TRIGRAM_DISTANCE = 300
  MAX_TOTAL_DISTANCE   = MAX_TRIGRAM_DISTANCE * MAX_TRIGRAM_DISTANCE # 90_000
  TEXT_TRIGRAMS_SIZE   = 600
  DEFAULT_MIN_CHARS    = 10

  Result = Struct.new(:language, :iso, :score, :ranked, keyword_init: true) do
    alias scores ranked
  end

  # Scripts that resolve to a single language by their Unicode block alone.
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

  # Unicode ranges per script, in detection priority order (mirrors whatlang's
  # scripts/detect.rs). The first script whose range contains a character claims
  # that character; the script with the most characters wins.
  SCRIPT_RANGES = [
    ['Latin',      [[0x61,0x7A],[0x41,0x5A],[0x80,0xFF],[0x100,0x17F],[0x180,0x24F],
                    [0x250,0x2AF],[0x1D00,0x1D7F],[0x1D80,0x1DBF],[0x1E00,0x1EFF],
                    [0x2100,0x214F],[0x2C60,0x2C7F],[0xA720,0xA7FF],[0xAB30,0xAB6F]]],
    ['Cyrillic',   [[0x400,0x484],[0x487,0x52F],[0x2DE0,0x2DFF],[0xA640,0xA69D],
                    [0x1D2B,0x1D2B],[0x1D78,0x1D78],[0xA69F,0xA69F]]],
    ['Arabic',     [[0x600,0x6FF],[0x750,0x7FF],[0x8A0,0x8FF],[0xFB50,0xFDFF],
                    [0xFE70,0xFEFF],[0x10E60,0x10E7F],[0x1EE00,0x1EEFF]]],
    ['Mandarin',   [[0x2E80,0x2E99],[0x2E9B,0x2EF3],[0x2F00,0x2FD5],[0x3005,0x3005],
                    [0x3007,0x3007],[0x3021,0x3029],[0x3038,0x303B],[0x3400,0x4DB5],
                    [0x4E00,0x9FCC],[0xF900,0xFA6D],[0xFA70,0xFAD9]]],
    ['Devanagari', [[0x900,0x97F],[0xA8E0,0xA8FF],[0x1CD0,0x1CFF]]],
    ['Hebrew',     [[0x590,0x5FF]]],
    ['Ethiopic',   [[0x1200,0x139F],[0x2D80,0x2DDF],[0xAB00,0xAB2F]]],
    ['Georgian',   [[0x10A0,0x10FF]]],
    ['Bengali',    [[0x980,0x9FF]]],
    ['Hangul',     [[0xAC00,0xD7AF],[0x1100,0x11FF],[0x3130,0x318F],[0x3200,0x32FF],
                    [0xA960,0xA97F],[0xD7B0,0xD7FF]]],
    ['Hiragana',   [[0x3040,0x309F]]],
    ['Katakana',   [[0x30A0,0x30FF]]],
    ['Greek',      [[0x370,0x3FF]]],
    ['Kannada',    [[0xC80,0xCFF]]],
    ['Tamil',      [[0xB80,0xBFF]]],
    ['Thai',       [[0xE00,0xE7F]]],
    ['Gujarati',   [[0xA80,0xAFF]]],
    ['Gurmukhi',   [[0xA00,0xA7F]]],
    ['Telugu',     [[0xC00,0xC7F]]],
    ['Malayalam',  [[0xD00,0xD7F]]],
    ['Oriya',      [[0xB00,0xB7F]]],
    ['Myanmar',    [[0x1000,0x109F]]],
    ['Sinhala',    [[0xD80,0xDFF]]],
    ['Khmer',      [[0x1780,0x17FF],[0x19E0,0x19FF]]],
    ['Armenian',   [[0x530,0x58F],[0xFB13,0xFB17]]]
  ].freeze

  # ISO 639-1 (with 639-3 fallback) lookup by language-name symbol, plus the
  # historical nil => nil entry. Internal; kept for backward compatibility.
  ISO_CODES = CODE_INFO.each_with_object(nil => nil) do |(_code, (name, iso)), h|
    h[name] = iso
  end.freeze

  NAME_TO_CODE = CODE_INFO.each_with_object({}) do |(code, (name, _iso)), h|
    h[name] ||= code
  end.freeze

  private_constant :MAX_TRIGRAM_DISTANCE, :MAX_TOTAL_DISTANCE, :TEXT_TRIGRAMS_SIZE,
                   :DEFAULT_MIN_CHARS, :DETERMINISTIC, :SCRIPT_RANGES, :ISO_CODES,
                   :NAME_TO_CODE

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
    return results if significant_char_count(text) < @min_chars

    positions = trigram_positions(text)
    candidates.each do |code, trigrams|
      name = CODE_INFO[code].first
      next unless allowed?(name)

      results[name] = MAX_TOTAL_DISTANCE - distance(trigrams, positions)
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
    text.each_char.count { |ch| !stop_char?(ch.ord) }
  end

  # Dominant Unicode script of the text, or nil if it has no script characters.
  def detect_script(text)
    counts = Hash.new(0)
    text.each_char do |ch|
      cp = ch.ord
      next if stop_char?(cp)

      SCRIPT_RANGES.each do |name, ranges|
        if ranges.any? { |lo, hi| cp >= lo && cp <= hi }
          counts[name] += 1
          break
        end
      end
    end
    return nil if counts.empty?

    counts.max_by { |_name, n| n }.first
  end

  # Text trigrams ranked by descending frequency, mapped to their rank index.
  # Mirrors whatlang's trigram extraction: punctuation/digits become spaces,
  # the stream is bounded by spaces, and runs of spaces are collapsed.
  def trigram_positions(text)
    chars = text.downcase.each_char.map { |c| stop_char?(c.ord) ? ' ' : c }
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

  # Space, ASCII punctuation, or digit: no value for script/language detection.
  def stop_char?(cp)
    cp <= 0x40 || (cp >= 0x5B && cp <= 0x60) || (cp >= 0x7B && cp <= 0x7E)
  end
end
