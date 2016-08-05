#this script:	 
#	-visits a directories tree lookin for .mp3 files
#	-extracts ARTIST and TITLE tags by means of mp3info tool
#	-formats them by replacing spaces and other special characters with '-'
#	-looks for the lyrics on musixmatch
#	-downloads the html page by means of wget and saves it into a html file
#	-parses the html file to extract the lyrics and save them into a txt file by means of xmllint combined  with xpath
#	-adds the lyrics to the id3 tag of the song by means of eyeD3
#	-removes the files

#There are two issues:
#	-some special characters should be substituted so, sometimes, the generated URL is not correct and the text cannot be found
#	-after a while the website blocks you, because it understand it's not a human who's searching for the lyrics

#This is a first quite-working version of the script. I'll work to solve those issues

#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters. Correct usage: ./search_lyrics.sh <root_folder>"
fi

song_array=()
while IFS=  read -r -d $'\0'; do
    song_array+=("$REPLY")
done < <(find "$1" -name "*.mp3" 2>/dev/null -print0)

for song in "${song_array[@]}"
do
	artist="$(mp3info -p %a "$song")"
	title="$(mp3info -p %t "$song")"
	echo "Song found: $title, $artist"

	artist=${artist//[ \',]/-}
	title=${title//[ \',]/-}

	html_file="$song".html
	txt_file="$song".txt
	
	echo "Accessing "https://www.musixmatch.com/lyrics/$artist/$title""
	wget https://www.musixmatch.com/lyrics/$artist/$title -q -O "$html_file"

	xmllint --html --xpath '//p[@class="mxm-lyrics__content"]/text()' "$html_file" 1>"$txt_file" 2>/dev/null
	echo "$txt_file created"
	exit

	eyeD3 --lyrics=ita:lyrics:"$(cat "$txt_file")" "$song"
	echo "Added lyrics to "$song""
	exit

	rm "$html_file"
	rm "$txt_file"

	eyeD3 "$song"
done
