# whatlanguage

Pure Ruby natural language detection for 160+ languages.

```ruby
require 'whatlanguage'

WhatLanguage.language("Que linguagem é essa? É uma pergunta sobre a língua portuguesa.")
# => :portuguese
```

- `gem install whatlanguage`
- No runtime dependencies.
- Supports 20+ writing systems.
- Ships a compact ~220 KB trigram model.
- Requires Ruby 3.0+ (JRuby and TruffleRuby also good)
- **Best on sentence-length text or longer.** Short texts can have ambiguous results.

> [!IMPORTANT]
> v2.0 has many breaking changes as the entire library has been reimplemented, though the core `WhatLanguage.language` API remains similar. Versions 1.0.6 and earlier (so the 2007-2025 run of the library) used a Bloom-filter technique and had 5MB of binary files to handle ~20 languages. Version 2.0 is more accurate, faster, and supports more languages from a single 220KB JSON file :-)

## How it works

Detection is in two stages. First, the dominant Unicode script is detected; scripts used by a single language (Greek, Korean, Thai, Japanese using Hiragana/Katakana) resolve immediately. For scripts shared by several languages (e.g. Latin, Cyrillic, Arabic, Hebrew) trigrams are ranked by frequency and compared against candidate language profiles.

The trigram profiles are vendored from [whatlang](https://github.com/greyblake/whatlang-rs), a port of [Franc](https://github.com/wooorm/franc), whose models are built from the public-domain UDHR corpus (see Credits). The model is a ~220 KB JSON file.


## Usage

Return a full detection result:

```ruby
wl = WhatLanguage.new
text = "Die Stadt plant neue Investitionen in den öffentlichen Verkehr"
result = wl.detect(text)
result.language   # => :german
result.iso        # => :de
result.score      # => 79018
result.ranked     # => [[:german, 79018], [:dutch, 77631], ... ]
```

Return ranked scores, or the raw score hash:

```ruby
wl.ranked(text)       # => [[:german, 79018], [:dutch, 77631], ... ]
wl.score_hash(text)   # => { german: 79018, dutch: 77631, ... }
```

Restrict candidate languages:

```ruby
wl = WhatLanguage.new(only: [:english, :german, :french])
```

Short Latin-script fragments are ignored by default because there is not enough signal to rank shared-script languages reliably. The threshold applies to the statistical trigram stage; scripts that identify a single supported language, such as Greek, Korean, or Thai, can still resolve from shorter text. The threshold can be adjusted:

```ruby
wl = WhatLanguage.new(min_chars: 0)
```

## Known limitations

- Short fragments are unreliable. For languages resolved by statistical comparison, fewer than 10 significant characters returns `nil` by default.
- Scores are relative ranking values, not probabilities. Use `#ranked` or `#detect.ranked` when close runners-up matter.
- Closely related written languages can be hard to separate, especially Norwegian Bokmål/Danish, Hebrew/Yiddish, and similar language pairs.
- Kanji-only Japanese text can classify as Chinese because Han characters alone do not identify the language.
- Romanized text is classified by Latin-script trigram profiles; it is not treated as native-script text.

## Credits

Contributions from Konrad Reiche, Salimane Adjao Moustapha, Andrew Cone, Lasse Skindstad Ebert, Henrik Nyh, Daniel Sandbecker, Michael Hartl, Pedro Lambert, Tobias Preuss, Pepijn Looije, and others appreciated.

The trigram language profiles in `lib/whatlanguage/trigrams.json` are taken from [whatlang](https://github.com/greyblake/whatlang-rs) (MIT, © Sergey Potapov), itself a derivative of [Franc](https://github.com/wooorm/franc) (MIT, © Titus Wormer). Those profiles are derived from the public-domain Universal Declaration of Human Rights translations.
