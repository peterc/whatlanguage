# Scanning and allocation benchmarks

These results compare against `294e041`, which already includes indexed scoring.
The gains below are additional to the [indexing gains](README.md).

```sh
BASELINE_REF=294e041 ruby benchmark/detection.rb > /tmp/whatlanguage-long-inputs.json
```

Measured on 2026-10-20 with Ruby 4.0.2, Apple M5, macOS 26.6.2. Seven paired
process runs, alternating baseline/current order, without concurrent test runs.
Timings and allocated-object counts are medians of warmed calls.
The [raw report](long-input-results.json) contains all workloads, samples, ranges,
startup measurements, and the library diff used for this run.

| Workload | Before, ms/call | After, ms/call | Speedup | Allocated objects, before → after |
| --- | ---: | ---: | ---: | ---: |
| English, 60 bytes | 0.1338 | 0.0889 | 1.50× | 1,152 → 195 |
| English sentence, 156 bytes | 0.2952 | 0.1811 | 1.63× | 3,061 → 273 |
| Repeated English, 10 KB | 4.6068 | 1.8766 | 2.45× | 58,375 → 196 |
| Repeated English, 1 MB | 489.9860 | 180.1590 | 2.72× | 5,750,876 → 197 |
| Seeded random Latin text, 5 KB | 9.1508 | 3.8314 | 2.39× | 144,022 → 4,869 |
| Accented Portuguese, 100 KB | 44.0687 | 31.0737 | 1.42× | 553,234 → 190,110 |
| Cyrillic, 100 KB | 31.3023 | 23.6990 | 1.32× | 313,521 → 106,691 |
| Japanese, 100 KB, script-only | 26.4160 | 24.7883 | 1.07× | 64,077 → 33,345 |
| English restricted to 3 languages | 0.1297 | 0.0824 | 1.57× | 1,035 → 78 |
| English restricted to 1 language | 0.0953 | 0.0497 | 1.92× | 1,031 → 74 |
| `detect`, English, 60 bytes | 0.1313 | 0.0907 | 1.45× | 1,152 → 199 |

Calls use `language` unless marked `detect`. The random Latin workload exercises
many distinct trigrams and the ranking limit; it is not an accuracy benchmark.

## Changes

- Count letters during script detection instead of scanning the input twice.
  For ASCII, count `A-Z` and `a-z` directly. For Unicode, retain the same script
  patterns and Japanese routing, using a loop that avoids a block allocation
  for each letter.
- Count trigrams with a rolling window and a reusable String key. Hash copies
  new String keys, so subsequent windows do not change earlier counts. ASCII
  inputs use bytes; other inputs retain Unicode letters and combining marks.
- Compare trigram counts and lexical order directly, without allocating arrays
  for each sort comparison. The frequency and tie ordering stay the same.
- Cache restricted candidate lists per script. A changed `languages` array
  invalidates the cache, preserving its existing mutable behavior.
- Use a maximum-score lookup for `language` and `language_iso`. `detect` and
  `ranked` still produce the full ranking.

The entire input is processed. Normalization, minimum lengths, preferences,
scores, and tie handling are unchanged.

## Limits and memory

The 197-object result is specific to repeated ASCII text with few distinct
trigrams. ASCII scanning no longer allocates per-character strings, and the
trigram buffer is reused. Inputs with more distinct trigrams allocate more
hash entries; Unicode processing still allocates character strings.

Object counts are not byte counts. Normalization and lowercasing still create
strings proportional to input size. These measurements do not establish peak
RSS or constant-memory processing.

Retained Ruby heap after all warmed workloads is essentially unchanged:
6,737,961 bytes before and 6,734,330 after. This includes benchmark fixtures and
the existing indexes, measured after GC. It is not process RSS.

Fresh-process first detection takes 8.833 ms before and 8.667 ms after; the second
call, which builds the Latin index, takes 4.037 ms before and 3.992 ms after.
The existing index build/memory tradeoff remains.

## Verification

All prior test assertions remain unchanged. The reference detector now also
retains the old preprocessing and winner-selection methods, so comparisons do
not share the newly optimized code.

New checks compare exact script counts and trigram ranks across ASCII controls,
Unicode, combining marks, case conversion, whitespace, unsupported scripts, and
seeded generated inputs. They also check tied winners, empty results, and
mutation of a configured detector's language list.

The full suite passes with **67 tests and 5,611 assertions** on Ruby 4.0.2,
Ruby 3.3.11, JRuby 9.4.14.0, and TruffleRuby 34.0.1. The timings above are
MRI measurements, not speedup claims for the other runtimes.
