# whatlanguage

by Peter Cooper

Text language detection. Quick, fast, memory efficient, and all in pure Ruby. Uses Bloom filters for aforementioned speed and memory benefits.

Works with Dutch, English, Farsi, French, German, Italian, Pinyin, Swedish, Portuguese, Russian and Spanish out of the box.

## Important note
  
This library was first built in 2007 and has received a few minor updates over the years. There are now more efficient and effective algorithms for doing language detection which I am investigating for a WhatLanguage 2.0.

This library has been updated to be distributed and to work on modern Ruby implementations but other than that, has had no improvements.

## Synopsis

Full Example

    require 'whatlanguage'
    
    texts = []
    texts << %q{Deux autres personnes ont été arrêtées durant la nuit}
    texts << %q{The links between the attempted car bombings in Glasgow and London are becoming clearer}
    texts << %q{En estado de máxima alertaen su nivel de crítico}
    texts << %q{Returns the object in enum with the maximum value.}
    texts << %q{Propose des données au sujet de la langue espagnole.}
    texts << %q{La palabra "mezquita" se usa en español para referirse a todo tipo de edificios dedicados.}
    
    texts.each { |text| puts "#{text[0..18]}... is in #{text.language.to_s.capitalize}" }

Initialize WhatLanguage with all filters

    wl = WhatLanguage.new(:all)

Return language with best score

    wl.language(text)

Return hash with scores for all relevant languages

    wl.process_text(text)

Convenience method on String

    "This is a test".language   # => "English"

Initialize WhatLanguage with certain languages

    wl = WhatLanguage.new(:english, :german, :french)

## Requirements

None, minor libraries (BloominSimple and BitField) included with this release.

## Installation

    gem install whatlanguage

To test, go into irb, then:

    require 'whatlanguage'
    "Je suis un homme".language

## License

MIT License

Copyright (c) 2007-2013 Peter Cooper

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
