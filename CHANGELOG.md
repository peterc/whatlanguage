# Changelog

## Unreleased

- Added a `whatlanguage` command-line executable that reads from files given as
  arguments (or stdin) and prints the ISO 639 code of the detected language, or
  `und` if undetermined. (#50, suggested by Keith Bennett)

## 2.0.0 / 2026-06-10

- Rewrote the detection engine from scratch. Bloom-filter dictionary lookups are
  replaced by a script router plus character-trigram out-of-place scoring (a pure-Ruby
  port of whatlang/Franc, public-domain UDHR-derived profiles).
- Expanded from 20 to 160+ languages across 20+ scripts.
- Removed the ~5 MB of binary `.lang` filter files and the wordlist corpus; the model
  is now a single ~220 KB JSON file. No dependencies beyond the standard library.
- Requires Ruby 3.0 or newer.
- Added `#detect`, `#ranked`, and `#score_hash` for callers that need result metadata
  or runner-up scores. `#scores` and `#process_text` remain as compatibility aliases.
- Added class-level convenience methods: `WhatLanguage.detect`, `.language`,
  `.language_iso`, `.ranked`, `.score_hash`, and `.languages`.
- Added `only:` for configured detectors, replacing positional language
  selection as the documented API.
- Removed the `String#language` and `String#language_iso` monkeypatch.
- Short shared-script fragments now return `nil` by default; pass `min_chars: 0`
  to preserve the previous best-effort behavior.
- Removed internals: `BloominSimple`, `BitField`, the filter-build scripts.

## 1.0.6 / 2016-01-28

- Minor test fixes and tweaks
- New release taking into account a handful of pull requests

## 1.0.5 / 2013-10-05

- Many more languages supported

## 1.0.4 / 2013-03-07

## 1.0.1 / 2008-08-22

- Public release
- Removed wordlists from distribution to reduce size

## 1.0.0 / 2007-07-02

- First version with pre-built English, French, and Spanish filters
