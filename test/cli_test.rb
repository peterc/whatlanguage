# frozen_string_literal: true

require_relative "test_helper"

require "open3"
require "rbconfig"

class CliTest < Minitest::Test
  EXE = File.expand_path("../exe/whatlanguage", __dir__)
  LIB = File.expand_path("../lib", __dir__)

  def test_reads_stdin_and_prints_iso_code
    stdout, stderr, status = run_cli(stdin_data: "Que linguagem é essa? É uma pergunta sobre a língua portuguesa.")
    assert status.success?, "cli failed\nstdout:\n#{stdout}\nstderr:\n#{stderr}"
    assert_equal "pt", stdout.strip
  end

  def test_reads_file_arguments
    stdout, stderr, status = run_cli(args: [File.expand_path("../README.md", __dir__)])
    assert status.success?, "cli failed\nstdout:\n#{stdout}\nstderr:\n#{stderr}"
    assert_equal "en", stdout.strip
  end

  def test_prints_und_when_undetermined
    stdout, _stderr, status = run_cli(stdin_data: "zzz")
    assert status.success?
    assert_equal "und", stdout.strip
  end

  private

  def run_cli(args: [], stdin_data: "")
    Open3.capture3(RbConfig.ruby, "-I#{LIB}", EXE, *args, stdin_data: stdin_data)
  end
end
