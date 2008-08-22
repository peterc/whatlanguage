require 'lib/whatlanguage'
require 'benchmark'

texts = []

texts << %q{Deux autres personnes ont été arrêtées durant la nuit. "Induite par le quinquennat, la modernisation de nos institutions (...) est un facteur de modernité et d'efficacité", a déclaré François Fillon. "Devant cet exécutif plus resserré et plus efficace, les pouvoirs du Parlement doivent être renforcés", a-t-il ajouté, en évoquant par exemple le contrôle parlementaire des nominations à "certains postes publics."

Le premier ministre, indiquant que le président Nicolas Sarkozy entendait "réunir une commission réunissant des personnalités incontestables pour leurs compétences et représentatives de notre diversité politique qui sera chargée d'éclairer ses choix" en matière de modernisation des institutions.

"Faut-il faire élire quelques députés au scrutin proportionnel? (...) Aucun sujet ne doit être tabou", a-t-il lâché. "Enfin nous devrons engager, comme le demande le Conseil constitutionnel, une révision de la carte des circonscriptions législatives. Ce travail sera engagé dans la transparence et en y associant l'opposition".}

texts << %q{The links between the attempted car bombings in Glasgow and London are becoming clearer. Seven are believed to be doctors or medical students, while one formerly worked as a laboratory technician.

Australian media have identified a man arrested at Brisbane airport as Dr Mohammed Haneef, 27.

Two men have been arrested in Blackburn under terror laws but police have not confirmed a link with the car bombs.

The pair were detained on an industrial estate and are being held at a police station in Lancashire on suspicion of offences under the Terrorism Act 2000.

Thousands of passengers travelling from Heathrow Airport's Terminal 4 face major delays after a suspect bag sparked a security alert.

BAA said the departure lounge was partially evacuated and departing passengers were being re-screened, causing some cancellations and delays.}

texts << %q{En estado de máxima alertaen su nivel de crítico. Cinco detenciones hasta el momento parecen indicar que los coches bomba de Londres y Glasgow fueron obra de una misma célula de terroristas islámicos con residencia en el Reino Unido, posiblemente con alguna conexión con otros grupos previamente desarticulados. La relación con éstos, singularmente con el núcleo de Dhiren Barot (condenado a 30 años por sus planes de llenar limusinas con bombonas de gas para provocar una masiva explosión), podría haber llevado a su detención tiempo atrás y su puesta en libertad al no existir suficientes pruebas contra ellos.}

texts << %q{Fern- und Regionalzüge, aber auch die S-Bahnen in den Großstädten stehen still. Gerade hat die Kanzlerin die Ergebnisse des Energiegipfels mit der Wirtschaft, den Energieerzeugern und Verbraucherschützern referiert, die "sachliche Atmosphäre" gelobt. Da wird der Umweltminister von einem Journalisten an seinen Ausspruch vom "Wirtschaftsstalinisten" erinnert, mit dem er jüngst den BASF-Vorstandschef Jürgen Hambrecht belegt hat im Streit um die ehrgeizigen Ziele der deutschen Klimapolitik. Wie haben denn seine Beiträge in der Runde für eine sachliche Atmosphäre ausgesehen? Gabriel überlegt, aber die Kanzlerin ist schneller.}

#texts << %q{Deux autres personnes ont été arrêtées durant la nuit}
#texts << %q{The links between the attempted car bombings in Glasgow and London are becoming clearer}
#texts << %q{En estado de máxima alertaen su nivel de crítico}
#texts << %q{Returns the object in enum with the maximum value.}
#texts << %q{Propose des données au sujet de la langue espagnole.}
#texts << %q{La palabra "mezquita" se usa en español para referirse a todo tipo de edificios dedicados.}
#texts << %q{Fern- und Regionalzüge, aber auch die S-Bahnen in den Großstädten stehen still.}

#texts.collect! { |t| (t + " ") * 5 }

@wl = WhatLanguage.new(:all)

puts Benchmark.measure {

100.times do  
texts.each { |text| 
  lang = text.language.to_s.capitalize
#  puts "#{text[0..18]}... is in #{lang}"
#  puts @wl.process_text(text).sort_by{|a,b| b }.reverse.inspect
#  puts "---"
}
end

}
