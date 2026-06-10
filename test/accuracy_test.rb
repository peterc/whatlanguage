# frozen_string_literal: true

require_relative "test_helper"

require "json"

class AccuracyTest < Minitest::Test
  FIXTURE_PATH = File.expand_path("fixtures/accuracy_samples.json", __dir__)

  def setup
    @detector = WhatLanguage.new
  end

  def test_significant_language_samples
    samples.each do |entry|
      expected = entry.fetch("language").to_sym
      sample = entry.fetch("sample")

      assert_equal expected, @detector.language(sample), "expected #{expected.inspect} for #{sample.inspect}"
    end
  end

  private

  def samples
    @samples ||= JSON.parse(File.read(FIXTURE_PATH))
  end
end
