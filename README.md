# FFilm-FFilm
Mit diesem Skript kann man mehrere Filmteile aneinander reihen, zu einem MP4. Und das auch mit Untertitel.

https://github.com/FlatheadV8/FFilm-FFilm

Es müssen alle zu verbindenden Filme genau den gleichen Aufbau haben.
Das heißt, um sicher zu gehen, sollten alle Teile mit genau den gleichen Parametern transkodiert worden sein.

Auch die Reihenfolge der einzelnen Spuren müssen in allen Teilen identisch sein.
Es darf also nicht die Audio-Spur in einem Teil die ID "0" und in dem anderen Teil die ID "1" haben.
Und auch müssen in allen oder in keinem eine Untertitel-Spur vorhanden sein.

...sie müssen wirklich alle absolut gleich aufgebaut sein!

Als erstes müssen wir eine Liste mit allen Filmteilen im richtigen Format anlegen:
----
  > echo "file 'teil1.mp4'" > filmteile.txt
  > echo "file 'teil2.mp4'" >> filmteile.txt
  > echo "file 'teil3.mp4'" >> filmteile.txt
----

jetzt können alle Teile verbunden werden:
----
  > ffmpeg -f concat -i filmteile.txt -c:v copy -c:a copy -c:s copy -f mp4 -y kompletterfilm.mp4
----

