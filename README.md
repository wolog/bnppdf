(version française à la fin de la page)

bnppdf
======

bnppdf is a small perl script able to parse PDF bank statement from BNP PARIBAS and extract data that can be read by personal finance softwares.

As of today, it is only able to generate a [homebank](http://homebank.free.fr/) compatible CSV, but it should be easy to adapt.

It has been successfully tested with 4 years of history on a dozen accounts. 

I will be happy to get feedback.

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

To use the script:

    $ pdttotext -layout file.pdf file.txt
    $ bnppdf.pl file.txt > file.csv

file.csv can be imported in homebank (<=4.4. If you're using homebank >=4.5 there is a small change to do inside the script, see the comments inside the source file) 

Version Française
=================

bnppdf est un petit script perl capable de lire les relevés de comptes PDF de BNP PARIBAS et d'extraire les données à importer logiciel de gestion de finances personnelles.

Pour le moment, seul le format de fichier CSV utilisé par [homebank](http://homebank.free.fr/) est pris en charge, mais il devrait être facile à adapter.

Il a été testé avec succès sur une douzaine de comptes, sur 4 ans d'historique.

Je serais heureux d'avoir des retours.

Le logiciel est mis à disposition sous la licence MIT. Voir le fichier joint pour le texte intégral.

Pour utiliser le script:

    $ pdttotext -layout fichier.pdf fichier.txt
    $ bnppdf.pl fichier.txt > fichier.csv

le csv est importable dans homebank (<=4.4. Pour une version >=4.5 y'a une modification à faire dans le script, voir les commentaires dans le source) 
