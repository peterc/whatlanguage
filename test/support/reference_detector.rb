# frozen_string_literal: true

module WhatLanguageTestSupport
  # Original scorer from 9507037, kept as an independent equivalence oracle.
  # Keep the arithmetic here unchanged when optimizing the production scorer.
  class ReferenceDetector < WhatLanguage
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
