# Indexed scoring benchmark

Run from the repository root:

```sh
ruby benchmark/detection.rb > /tmp/whatlanguage-benchmark.json
```

The default baseline is commit `9507037db755ad0d297f899bef527200b80e9822`.
Override it with `BASELINE_REF`; change the default seven rounds with `ROUNDS`.
The baseline revision must be available in the local Git repository.

The script extracts the baseline library and model into a temporary directory,
then runs the baseline and working tree in separate Ruby processes. Process order
alternates between rounds. Each warmed case reports elapsed time per `language`
call and allocated objects; separate fresh processes measure library loading and
the first two detections. JSON output includes every sample, medians, ranges,
Ruby version, baseline revision, and the library's uncommitted diff.

Retained heap measurements use `ObjectSpace.memsize_of_all` after GC on MRI. They
measure Ruby heap objects, not process RSS. The warmed measurement includes the
fixtures and detectors as well as all six script indexes, with the same workload
in each process.

## Why results remain equivalent

The old scorer checks each of a language's profile trigrams against the input.
An absent trigram costs 300; a present trigram costs its absolute rank difference.
The indexed scorer starts with every profile trigram absent and substitutes the
actual distance for each matching trigram. It then applies the same short-input
adjustment, clamp, and preference bonus.

Corrections can be positive: an input trigram can have a rank beyond 300. The
implementation preserves this behavior and the original candidate order, including
ties. Profiles are unchanged.

Indexes are shared by detector instances and built separately for each script.
The first unrestricted call uses the original scan; the second builds the index.
This keeps one-shot CLI detection from paying the build cost. Restricted
candidate sets keep the original scan, and script-only detection does not use an
index.

The existing tests are unchanged. Added tests compare against the original scorer
on real text, generated text from every statistical script, noise, Unicode variants,
multiple minimum lengths, and candidate selections. They check ordered score
hashes, rankings, result metadata, names, and ISO codes. Separate arithmetic
checks cover empty input-trigram sets, missing matches, and rank-count
boundaries through 600 input trigrams.

The full suite passes with 64 tests and 5,309 assertions on Ruby 4.0.2, Ruby 3.3.11,
JRuby 9.4.14.0, and TruffleRuby 34.0.1. Performance results below are MRI
measurements; correctness checks on the other runtimes do not establish their
speedups.

## Measured results

Measured on 2026-10-20 with Ruby 4.0.2, Apple M5, macOS 26.6.2. Seven paired
process runs, with no concurrent test runs. Values below are medians; the
[raw report](indexed-scoring-results.json) includes ranges and every sample.

| Workload | Before, ms/call | After, ms/call | Speedup | Allocated objects, before → after |
| --- | ---: | ---: | ---: | ---: |
| English, 60 bytes | 2.0359 | 0.1332 | 15.28× | 1,271 → 1,152 |
| English sentence, 156 bytes | 2.0218 | 0.2949 | 6.86× | 3,181 → 3,060 |
| Repeated English, 10 KB | 6.4964 | 4.5614 | 1.42× | 58,550 → 58,375 |
| Repeated English, 1 MB | 486.2400 | 490.1940 | 0.99× | 5,751,050 → 5,750,876 |
| Cyrillic | 0.4724 | 0.2296 | 2.06× | 2,852 → 2,837 |
| Arabic | 0.2719 | 0.1918 | 1.42× | 2,402 → 2,398 |
| Devanagari | 0.2953 | 0.2008 | 1.47× | 2,304 → 2,299 |
| Hebrew | 0.2220 | 0.1936 | 1.15× | 2,186 → 2,185 |
| Ethiopic | 0.1241 | 0.0953 | 1.30× | 678 → 678 |
| Japanese, script-only | 0.0522 | 0.0525 | 0.99× | 139 → 139 |
| Below minimum length | 0.0022 | 0.0023 | 0.99× | 32 → 32 |
| English restricted to 3 languages | 0.1291 | 0.1284 | 1.00× | 1,035 → 1,035 |
| English restricted to 1 language | 0.0948 | 0.0945 | 1.00× | 1,031 → 1,031 |

The large gain is in repeated unrestricted short-text detection, especially
Latin's 121 candidate profiles. Long text remains dominated by normalization,
script detection, and trigram extraction; the 1 MB timing ranges overlap
(484–493 ms before, 479–498 ms after), so this does not establish a long-text
speedup. Restricted, below-minimum, and script-only paths are effectively unchanged.
The Ethiopic workload exercises its scorer but is not an accuracy benchmark.

### Startup and memory tradeoffs

| Fresh-process measurement | Before | After |
| --- | ---: | ---: |
| `require "whatlanguage"` | 0.795 ms | 0.855 ms |
| First English detection | 8.815 ms | 8.711 ms |
| Second English detection | 2.046 ms | 4.059 ms |
| Retained heap after require + first detection | 3,236,346 bytes | 3,236,837 bytes |
| Retained heap after require + second detection | 3,236,410 bytes | 4,607,901 bytes |
| Retained heap after all warmed workloads | 4,261,996 bytes | 6,426,191 bytes |

First-detection timing includes model loading and lazy Unicode initialization.
These timings exclude starting the Ruby interpreter. The second call builds
the Latin index; later calls use the warmed path measured above. Thus a process
doing only two detections can be slower, while the build cost amortizes over a
handful of short-text calls.

The Latin index adds approximately **1.31 MiB** of retained Ruby heap. Loading
indexes for every statistical script adds approximately **2.06 MiB**. Indexes
are shared rather than duplicated for each detector instance. This optimization
trades persistent memory for throughput; it does not claim to reduce model size
or solve the large-input allocation cost.
