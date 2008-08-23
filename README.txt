whatlanguage
    by Peter Cooper
    http://www.petercooper.co.uk/
    http://www.rubyinside.com/

== DESCRIPTION:
  
Text language detection. Quick, fast, memory efficient, and all in pure Ruby. Uses Bloom filters for aforementioned speed and memory benefits.

Works with Dutch, English, Farsi, French, German, Swedish, Portuguese, Russian and Spanish out of the box.

== FEATURES/PROBLEMS:
  
* It can be made far more efficient at the comparison stage, but all in good time..! It still beats literal dictionary approaches.
* No filter selection yet, you get 'em all loaded.
* Tests are reasonably light.

== SYNOPSIS:

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

== REQUIREMENTS:

* None, minor libraries (BloominSimple and BitField) included with this release.

== INSTALLATION:

  gem sources -a http://gems.github.com
  sudo gem install peterc-whatlanguage

  To test, go into irb, then:

  require 'whatlanguage'
  "Je suis un homme".language

== LICENSE:

(The MIT License)

Copyright (c) 2007-2008 Peter Cooper

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
