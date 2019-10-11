#!/usr/bin/env bash

#==============================================================================#
#
# so kann man es auch von Hand machen:
#
# echo "file 'teil_1.mp4'" > videos.txt
# echo "file 'teil_2.mp4'" >> videos.txt
# echo "file 'teil_3.mp4'" >> videos.txt
#
# ffmpeg -f concat -i videos.txt -c:v copy -c:a copy -c:s copy -f mp4 -y komplett.mp4
#
#==============================================================================#

#VERSION="v2019082800"
VERSION="v2019093000"

#------------------------------------------------------------------------------#

hilfe()
{
echo "#
# Mit diesem Skript kann man mehrere Filmteile aneinander reihen.
# Allerdings sollte man darauf achten, dass alle Teile zueinander kompatibel
# sind, sonst kann es beim abspielen zu Problemen kommen.
#
# Es ist darauf zu achten, dass diese Filmteile mindestens die gleiche
# Bildschirmauflösung, Bildwiederholrate und Codecs besitzen.
# Auch müssen Video-, Audio-, Untertitel-Spuren in allen Filmteile
# genau die gleiche Reihenfolge haben.
# (Wenn das nicht so ist muss man mit Mapping arbeiten, was dieses Skript
# nicht beherscht.)
# Die Filmteile müssen auch in ihren Audio-Spuren gleichviele Kanäle haben.
# Zum Beispiel sollten alle Stereo (2) oder Dolby (6) haben.
# Beides gemischt geht nicht.
#
# Mit diesem Skript kann man gewaltigen Ausschuss produzieren, der auf dem
# ersten Blick nicht einmal auffällt!!!
# Damit meine ich, dass es (wenn man bestimmte Fehler macht) völlig zufällig
# sein kann, ob der Film nachher auf anderen Geräten abgespielt werden kann.
# Meistens wird er mit VLC und MPlayer gut laufen aber im Browser, auf dem Handy
# oder der MediaBox sowie anderen Geräten u.U. nicht komplett oder
# überhaupt nicht!
#
# Die sicherste Methode, mit diesem Skript gute Ergebnisse zu erhalten, ist
# z.B. diese:
# verwenden Sie zum konvertieren der einzelnen Filmteile, die später mit diesem
# Skript aneinander gereiht werden sollen, das Skript Film2MP4.sh
# (https://github.com/FlatheadV8/Film2MP4).
# Dabei ist unbedingt darauf zu achten, dass Sie für alle Einzelteile jeweils
# genau die gleichen Angaben für diese beiden Parameter verwenden:
#   -soll_xmaly
#   -dar
# zum Beispiel würde man für 3 Teile dieses tun:
#   ~/bin/Film2MP4.sh -soll_xmaly 1920x1080 -dar 16:9 -q 1.avi -z teil_1.mp4
#   ~/bin/Film2MP4.sh -soll_xmaly 1920x1080 -dar 16:9 -q 2.avi -z teil_2.mp4
#   ~/bin/Film2MP4.sh -soll_xmaly 1920x1080 -dar 16:9 -q 3.avi -z teil_3.mp4
#   ~/bin/Film+Film.sh komplett teil_1.mp4 teil_2.mp4 teil_3.mp4
#
# Der fertige Film, aus diesem Beispiel, hat am Ende den Namen "komplett.mkv".
# Dieses Skript kann nur MKV-Dateien produzieren.
#
# Es ist auch sinnvoll , dass man mit dem MKV-Format arbeitet,
# andernfalls muss dieses Skript den entsprechenden Film-Teil
# vor dem zusammenfügen ersteinmal ins MKV-Format übersetzen (das ist aber nicht schlimm).
#
# Wichtig zu sagen an dieser Stelle ist auch, dass Filme, die mit libx264
# erzeugt wurden werden beim zusammenfühgen keine Probleme verursachen, Filme
# die mit dem (von FF) internen Codec h264 erzeugt wurden, können nach dem
# zusammenfühgen unbrauchbare Ergebnisse erzielen!
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - ffmpeg
#  - mkvmerge (aus dem Paket mkvtoolnix)
#

Beispiel:
> ${0} Filmfertig [Filmteil1.mp4] [Filmteil2.mp4] [Filmteil3.mp4]
"
}

#------------------------------------------------------------------------------#

if [ -e "$1" ] ; then
	hilfe
	exit 2
fi

if [ "x$3" == x ] ; then
	hilfe
	exit 3
fi

#------------------------------------------------------------------------------#


#set -x
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

LANG=C		# damit AWK richtig rechnet
SCHNELLSTART="-movflags faststart"

#==============================================================================#

if [ -z "$1" ] ; then
	echo "${0} Filmfertig [Filmteil1.mp4] [Filmteil2.mp4] [Filmteil3.mp4]"
	exit 4
fi

AUFRUF="${0} $@"

#==============================================================================#
### Programm

PROGRAMM="$(which avconv)"
if [ -z "${PROGRAMM}" ] ; then
        PROGRAMM="$(which ffmpeg)"
fi

if [ -z "${PROGRAMM}" ] ; then
        echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
        exit 5
fi

#==============================================================================#
### Es können nur Filmteile im Matroska-Format aneinandergereiht werden.

NAME_NEU="${1}"
shift
FILM_TEILE="${@}"
NAME_TEST="${1}"

rm -f ${NAME_NEU}.txt ${NAME_NEU}_Filmliste.txt
echo "${AUFRUF}" > ${NAME_NEU}.txt

for FILMDATEI in ${FILM_TEILE}
do
	echo | tee -a ${NAME_NEU}.txt
	echo "-> ${FILMDATEI}" | tee -a ${NAME_NEU}.txt

	if [ ! -r "${FILMDATEI}" ] ; then
        	echo "Der Film '${FILMDATEI}' konnte nicht gefunden werden. Abbruch!"
        	exit 6
	else
		### Anzeige, welche Spuren im Film vorhanden sind
		echo "Video	->  $(ffmpeg -i ${NAME_TEST} 2>&1 | fgrep 'Video:')" | tee -a ${NAME_NEU}.txt
		echo "Audio	->  $(ffmpeg -i ${NAME_TEST} 2>&1 | fgrep 'Audio:')" | tee -a ${NAME_NEU}.txt
		echo "Untert.	->  $(ffmpeg -i ${NAME_TEST} 2>&1 | fgrep 'Subtitle:')" | tee -a ${NAME_NEU}.txt

		### den Film in die Filmliste eintragen
		echo "echo \"file '${FILMDATEI}'\" >> ${NAME_NEU}_Filmliste.txt" | tee -a ${NAME_NEU}.txt
		echo "file '${FILMDATEI}'" >> ${NAME_NEU}_Filmliste.txt
	fi
done

#==============================================================================#
### Filmteile aneinander reihen

UNTERTITEL_VORHANDEN="$(ffmpeg -i ${NAME_TEST} 2>&1 | fgrep 'Subtitle:' | awk '{print $1}')"

if [ "x${UNTERTITEL_VORHANDEN}" != "x" ] ; then
	UNTERTITEL_AN="-c:s copy"
fi

echo "
ffmpeg -f concat -i ${NAME_NEU}_Filmliste.txt -c:v copy -c:a copy ${UNTERTITEL_AN} ${SCHNELLSTART} -f mp4 ${NAME_NEU}.mp4
" | tee -a ${NAME_NEU}.txt
ffmpeg -f concat -i ${NAME_NEU}_Filmliste.txt -c:v copy -c:a copy ${UNTERTITEL_AN} ${SCHNELLSTART} -f mp4 ${NAME_NEU}.mp4

#------------------------------------------------------------------------------#

rm -v ${NAME_NEU}_Filmliste.txt

echo

ls -lh ${NAME_NEU}.mp4 ${NAME_NEU}.txt
exit
