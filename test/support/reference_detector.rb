# frozen_string_literal: true

module WhatLanguageTestSupport
  # Original scorer from 9507037, kept as an independent equivalence oracle.
  # Keep the arithmetic here unchanged when optimizing the production scorer.
  class ReferenceDetector < WhatLanguage
    def language(text)
      detect(text)&.language
    end

    def language_iso(text)
      detect(text)&.iso
    end

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

        results[name] = MAX_TOTAL_DISTANCE - reference_distance(trigrams, positions)
        results[name] += bonus if SHORT_TEXT_PREFERENCES.include?(name)
      end
      results
    end

    private

    def significant_char_count(text)
      text.each_char.count { |ch| /\p{L}/.match?(ch) }
    end

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

      if counts['Hiragana'] + counts['Katakana'] > 0
        japanese = counts['Mandarin'] + counts['Hiragana'] + counts['Katakana']
        counts.delete('Mandarin')
        counts.delete('Katakana')
        counts['Hiragana'] = japanese
      end

      counts.max_by { |_name, n| n }.first
    end

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

    def reference_distance(profile, positions)
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
end
