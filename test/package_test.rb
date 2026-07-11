# frozen_string_literal: true

require_relative "test_helper"

require "open3"
require "rbconfig"
require "tmpdir"

class PackageTest < Minitest::Test
  def test_built_gem_loads_and_contains_expected_runtime_files
    Dir.mktmpdir("whatlanguage-package-test") do |dir|
      gem_path = File.join(dir, "whatlanguage.gem")
      build_gem(gem_path)

      files = gem_files(gem_path)
      assert_includes files, "lib/whatlanguage.rb"
      assert_includes files, "lib/whatlanguage/languages.rb"
      assert_includes files, "lib/whatlanguage/trigrams.json"
      assert_includes files, "exe/whatlanguage"
      refute_includes files, "lib/whatlanguage/string.rb"
      assert_empty files.grep(%r{\Atest/})

      unpack_dir = File.join(dir, "unpacked")
      unpack_gem(gem_path, unpack_dir)

      lib_dir = Dir[File.join(unpack_dir, "whatlanguage*", "lib")].first
      refute_nil lib_dir
      assert_package_loads(lib_dir)
    end
  end

  private

  def build_gem(gem_path)
    stdout, stderr, status = Open3.capture3("gem", "build", "whatlanguage.gemspec", "--output", gem_path)
    assert status.success?, "gem build failed\nstdout:\n#{stdout}\nstderr:\n#{stderr}"
  end

  def gem_files(gem_path)
    stdout, stderr, status = Open3.capture3("gem", "specification", gem_path, "files")
    assert status.success?, "gem specification failed\nstdout:\n#{stdout}\nstderr:\n#{stderr}"
    stdout.lines.grep(/\A- /).map { |line| line.sub(/\A- /, "").strip }
  end

  def unpack_gem(gem_path, unpack_dir)
    stdout, stderr, status = Open3.capture3("gem", "unpack", gem_path, "--target", unpack_dir)
    assert status.success?, "gem unpack failed\nstdout:\n#{stdout}\nstderr:\n#{stderr}"
  end

  def assert_package_loads(lib_dir)
    code = <<~RUBY
      require "whatlanguage"
      abort "wrong language" unless WhatLanguage.language("this is a longer English sentence with enough common words") == :english
      abort "string monkeypatch present" if "text".respond_to?(:language)
    RUBY

    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-I#{lib_dir}", "-e", code)
    assert status.success?, "packaged gem failed to load\nstdout:\n#{stdout}\nstderr:\n#{stderr}"
  end
end
