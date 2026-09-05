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

> [!NOTE]
> Version 2.1 improves Unicode and mixed-script Japanese handling and adds a fixed
> preference for five widely spoken languages on short texts. The public API and
> default 10-letter minimum for statistical detection are unchanged.

Detection is in two stages. First, the dominant Unicode script is detected from letters; scripts used by a single supported language (Greek, Korean, Thai, Japanese using Hiragana/Katakana) resolve immediately. When kana is present, Han, Hiragana, and Katakana count together as Japanese, while a dominant unrelated script can still win. For scripts shared by several languages (e.g. Latin, Cyrillic, Arabic, Hebrew) trigrams are ranked by frequency and compared against candidate language profiles.

Digits, punctuation, and emoji do not count toward the minimum text length and are treated as separators when extracting trigrams. Combining marks are preserved in trigrams but do not count as additional letters. Unicode script coverage follows the Unicode version supported by your Ruby runtime.

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

Return ranked scores, or the score hash:

```ruby
wl.ranked(text)       # => [[:german, 79018], [:dutch, 77631], ... ]
wl.score_hash(text)   # => { german: 79018, dutch: 77631, ... }
```

Restrict candidate languages:

```ruby
wl = WhatLanguage.new(only: [:english, :german, :french])
```

For short texts, English, Chinese (Mandarin), Hindi, Spanish, and French receive
a built-in preference. These five were selected using the
[2025 total-speaker ranking](https://www.visualcapitalist.com/ranked-the-worlds-most-spoken-languages-in-2025/)
(including second-language speakers). Eligible trigram candidates receive the
same bonus: 600 ranking points through 10 letters, decreasing linearly to zero
at 50 letters. Longer texts keep their original scores. The preference is not
configurable; it respects `only:` and script detection. Chinese already resolves
from its script, so it does not need a statistical bonus. Scores exposed by the
API include the bonus and remain ranking values, not probabilities.

Short shared-script fragments are ignored by default because there is not enough signal to rank their languages reliably. The threshold applies to the statistical trigram stage; scripts that identify a single supported language, such as Greek, Korean, or Thai, can still resolve from shorter text. The threshold can be adjusted:

```ruby
wl = WhatLanguage.new(min_chars: 0)
```

## Command line

Installing the gem also installs a `whatlanguage` executable that reads from files given as arguments (or stdin) and prints the ISO 639 code of the detected language, or `und` if undetermined:

```bash
$ whatlanguage README.md
en
$ echo "Wie geht es dir heute?" | whatlanguage
de
```

## Known limitations

- Short texts can be ambiguous. Built-in preferences help some phrases but can bias others toward preferred languages. Statistical detection returns `nil` below 10 letters by default.
- Scores indicate relative rank, not probability or confidence. Use `#ranked` to inspect alternatives.
- Similar written languages, such as Norwegian Bokmål/Danish and Hebrew/Yiddish, can be confused.
- Japanese without kana is classified as Chinese when Han is the dominant script.
- Romanized text is compared with Latin-script profiles, so it may not resolve to its original language.

## Credits

Contributions from Konrad Reiche, Salimane Adjao Moustapha, Andrew Cone, Lasse Skindstad Ebert, Henrik Nyh, Daniel Sandbecker, Michael Hartl, Pedro Lambert, Tobias Preuss, Pepijn Looije, Keith Bennett, and others appreciated.

The trigram language profiles in `lib/whatlanguage/trigrams.json` are taken from [whatlang](https://github.com/greyblake/whatlang-rs) (MIT, © Sergey Potapov), itself a derivative of [Franc](https://github.com/wooorm/franc) (MIT, © Titus Wormer). Those profiles are derived from the public-domain Universal Declaration of Human Rights translations.
