# frozen_string_literal: true

# Compare this working tree with a real Git revision in isolated Ruby processes.
# No gems beyond the standard library are required.
#   ruby benchmark/detection.rb > /tmp/whatlanguage-benchmark.json
#   BASELINE_REF=9507037 ROUNDS=7 ruby benchmark/detection.rb
require "json"

ROOT = File.expand_path("..", __dir__)
SHORT_TEXT = "This is a longer English sentence with enough common words. "

def median(values)
  sorted = values.sort
  middle = sorted.size / 2
  sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
end

if ARGV.first == "--worker"
  require "benchmark"
  heap_measurement = begin
    require "objspace"
    ObjectSpace.respond_to?(:memsize_of_all)
  rescue LoadError
    false
  end
  lib, mode = ARGV[1, 2]
  $LOAD_PATH.unshift(lib)
  GC.start
  heap_before = ObjectSpace.memsize_of_all if heap_measurement
  allocations_before = GC.stat(:total_allocated_objects)
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  require "whatlanguage"
  load_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000

  if mode == "cold"
    first_ms = Benchmark.realtime { WhatLanguage.language(SHORT_TEXT) } * 1000
    first_allocations = GC.stat(:total_allocated_objects) - allocations_before
    GC.start
    first_heap = ObjectSpace.memsize_of_all - heap_before if heap_measurement
    second_ms = Benchmark.realtime { WhatLanguage.language(SHORT_TEXT) } * 1000
    allocations = GC.stat(:total_allocated_objects) - allocations_before
    GC.start
    puts JSON.generate(
      require_ms: load_ms, first_detection_ms: first_ms, second_detection_ms: second_ms,
      allocations_after_first: first_allocations, allocations_after_second: allocations,
      retained_heap_after_first_bytes: first_heap,
      retained_heap_bytes: heap_measurement ? ObjectSpace.memsize_of_all - heap_before : nil
    )
    exit
  end

  fixtures = JSON.parse(File.read(File.join(ROOT, "test/fixtures/accuracy_samples.json")))
                 .to_h { |entry| [entry.fetch("language"), entry.fetch("sample")] }
  repeat_to_bytes = ->(text, bytes) { (text * (bytes / text.bytesize + 1)).byteslice(0, bytes).scrub("") }
  random = Random.new(294041)
  alphabet = ("a".."z").to_a + [" "]
  diverse_latin = Array.new(5000) { alphabet.sample(random: random) }.join
  all = WhatLanguage.new
  cases = {
    "latin_short" => [all, SHORT_TEXT, 200],
    "latin_sentence" => [all, fixtures.fetch("english"), 150],
    "latin_10kb" => [all, (SHORT_TEXT * 170)[0, 10_000], 30],
    "latin_1mb" => [all, (SHORT_TEXT * 17_000)[0, 1_000_000], 1],
    "latin_diverse_5kb" => [all, diverse_latin, 10],
    "latin_accented_100kb" => [all, repeat_to_bytes.call(fixtures.fetch("portuguese"), 100_000), 3],
    "cyrillic_100kb" => [all, repeat_to_bytes.call(fixtures.fetch("russian"), 100_000), 3],
    "script_only_100kb" => [all, repeat_to_bytes.call(fixtures.fetch("japanese"), 100_000), 3],
    "cyrillic" => [all, fixtures.fetch("russian"), 150],
    "arabic" => [all, fixtures.fetch("arabic"), 150],
    "devanagari" => [all, fixtures.fetch("hindi"), 150],
    "hebrew" => [all, fixtures.fetch("hebrew"), 150],
    "ethiopic" => [all, "አማርኛ ትግርኛ " * 10, 150],
    "script_only" => [all, fixtures.fetch("japanese"), 200],
    "below_minimum" => [all, "hello", 200],
    "only_3_languages" => [
      WhatLanguage.new(only: [:english, :german, :french]), SHORT_TEXT, 200
    ],
    "only_1_language" => [WhatLanguage.new(only: :english), SHORT_TEXT, 200]
  }
  cases["detect_latin_short"] = [all, SHORT_TEXT, 200, :detect]
  measurements = cases.to_h do |name, (detector, text, iterations, api)|
    api ||= :language
    (text.bytesize >= 100_000 ? 2 : 20).times { detector.public_send(api, text) }
    GC.start
    before = GC.stat(:total_allocated_objects)
    elapsed = Benchmark.realtime { iterations.times { detector.public_send(api, text) } }
    [name, {
      ms_per_call: elapsed * 1000 / iterations,
      allocations_per_call: (GC.stat(:total_allocated_objects) - before).to_f / iterations,
      bytes: text.bytesize, iterations: iterations, api: api
    }]
  end
  GC.start
  puts JSON.generate(
    cases: measurements,
    retained_heap_bytes: heap_measurement ? ObjectSpace.memsize_of_all - heap_before : nil
  )
  exit
end

require "open3"
require "tmpdir"
require "fileutils"
require "rbconfig"

def capture!(*command)
  out, err, status = Open3.capture3(*command, chdir: ROOT)
  raise "#{command.first} failed: #{err}" unless status.success?

  out
end

revision = ENV.fetch("BASELINE_REF", "9507037db755ad0d297f899bef527200b80e9822")
rounds = Integer(ENV.fetch("ROUNDS", "7"))
raise "ROUNDS must be positive" unless rounds.positive?

report = {
  ruby: RUBY_DESCRIPTION, platform: RUBY_PLATFORM,
  measured_at_utc: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  baseline_ref: capture!("git", "rev-parse", revision).strip,
  current_head: capture!("git", "rev-parse", "HEAD").strip,
  working_tree_diff: capture!("git", "diff", "--", "lib/whatlanguage.rb"),
  rounds: rounds, warm: {}, cold: {}
}
Dir.mktmpdir("whatlanguage-baseline") do |directory|
  %w[lib/whatlanguage.rb lib/whatlanguage/languages.rb
     lib/whatlanguage/version.rb lib/whatlanguage/trigrams.json].each do |path|
    target = File.join(directory, path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, capture!("git", "show", "#{revision}:#{path}"))
  end
  libraries = { "baseline" => File.join(directory, "lib"), "current" => File.join(ROOT, "lib") }
  %w[warm cold].each do |mode|
    samples = libraries.to_h { |name, _lib| [name, []] }
    rounds.times do |round|
      # Alternate process order to reduce systematic ordering bias.
      order = round.even? ? libraries.to_a : libraries.to_a.reverse
      order.each do |name, lib|
        samples[name] << JSON.parse(capture!(RbConfig.ruby, __FILE__, "--worker", lib, mode))
      end
      warn "#{mode}: completed pair #{round + 1}/#{rounds}"
    end
    report[mode.to_sym][:raw_samples] = samples
    if mode == "warm"
      report[:warm][:cases] = samples.fetch("baseline").first.fetch("cases").keys.to_h do |name|
        measurements = samples.transform_values do |runs|
          values = runs.map { |run| run.fetch("cases").fetch(name) }
          {
            median_ms: median(values.map { |value| value.fetch("ms_per_call") }),
            median_allocations: median(values.map { |value| value.fetch("allocations_per_call") }),
            min_ms: values.map { |value| value.fetch("ms_per_call") }.min,
            max_ms: values.map { |value| value.fetch("ms_per_call") }.max
          }
        end
        measurements["speedup"] = measurements["baseline"][:median_ms] / measurements["current"][:median_ms]
        [name, measurements]
      end
      report[:warm][:median_retained_heap_bytes] = samples.transform_values do |runs|
        values = runs.filter_map { |run| run["retained_heap_bytes"] }
        median(values) unless values.empty?
      end
    else
      report[:cold][:medians] = samples.transform_values do |runs|
        runs.first.keys.to_h do |key|
          values = runs.filter_map { |run| run[key] }
          [key, values.empty? ? nil : median(values)]
        end
      end
    end
  end
end
puts JSON.pretty_generate(report)
