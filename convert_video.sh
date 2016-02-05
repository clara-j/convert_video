#!/bin/bash
source /home/files/Dropbox/Automator/bash.commands

# this script is to automatically convert a folder of video files to H.265
# You need to change SRC -- Source folder and DEST -- Destination folder

#Preset Options
#    ultrafast
#    superfast
#    veryfast
#    faster
#    fast
#    medium
#    slow
#    slower
#    veryslow
#    placebo

LogAndEcho () {

	echo $1
	echo $1 >> $LogFile

}

function ShowTime () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"d "$hour"h "$min"m "$sec"s
}


EXT="mkv\\|avi\\|mp4\\|mov\\"
#SRC="/media/Pool2/Temp/Scratch/"
SRC="/media/TV/Breaking Bad/Season 05/"
DEST="/media/Pool2/Temp"
DEST_EXT=mkv
LogFile="/home/files/Dropbox/Automator/Logs"
HANDBRAKE_CLI=HandBrakeCLI
Quality=18
Preset=medium
MAXDEPTH="-maxdepth 0"
SIZE="-size +5G"

LogFile="$LogFile/ConvertH.265.`date +%h.%d.%y`.$$.log"

if [[ "$1" != "" ]] ; then
	SRC="$1"
fi

if [[ "$2" != "" ]] ; then
        Quality="$2"
fi


LogAndEcho "----------Settings----------"
LogAndEcho "Source:........$SRC"
LogAndEcho "Destination:...$DEST"
LogAndEcho "Extension:.....$DEST_EXT"
LogAndEcho "Quality:.......$Quality"
LogAndEcho "Preset:........$Preset"
LogAndEcho "----------------------------"

OIFS="$IFS"
IFS=$'\n'
#echo "find $SRC -maxdepth 0 -iregex '.*\(mkv\|mp4\|avi\|mov\)'"
#for FILE in `find "$SRC" -maxdepth 4 -mtime +1 -size +300M -iregex '.*\(mkv\|mp4\|avi\|mov\)'`
for FILE in `find "$SRC" -maxdepth 4  -size +300M -iregex '.*\(mkv\|mp4\|avi\|mov\)'`
do
        filename=$(basename "$FILE")
        extension=${filename##*.}
        filename=${filename%.*}
	FILE_DIR=$(dirname "$FILE")


		Is265=`avprobe "$FILE" 3>&1  2>&3|grep HEVC |wc -l`
		
			LogAndEcho ""
			LogAndEcho "``"
			LogAndEcho "----------------------------"
			LogAndEcho "Starting file: $FILE - `date`"
		
		
		if [ "0" == "$Is265" ] ; then
			
			
			OriginalLength=`avconv -i "$FILE" 2>&1 | grep 'Duration' | awk '{print $2}' | sed s/,//`
			OriginalSize=`du -h "$FILE" |cut -f1`
			OriginalSizeK=`du "$FILE" |cut -f1`
			LogAndEcho "Original File Size: $OriginalSize"
			LogAndEcho "Original File Length: $OriginalLength"

			StartTime=`date +%s`
			ionice -c 3 nice -10 $HANDBRAKE_CLI -i "$FILE" -o "$DEST/$filename.${DEST_EXT}" -e x265 --encoder-preset $Preset -q $Quality -a "1,2,3,4,5,6" -E copy --custom-anamorphic --keep-display-aspect -O --markers -s "1,2,3,4,5,6"
			#echo "asdfasfjgaskjfda" > "$DEST/$filename.${DEST_EXT}"
			eCode="$?"
			
			echo "eCode: $eCode"

			if [ "$eCode" -ne "0" ]; then
				LogAndEcho "Failed!!!"
				push "convert" "error"
				exit
			fi

			EndTime=`date +%s`

			RunTime=$(($EndTime-$StartTime))
			
			if [ -e "$DEST/$filename.${DEST_EXT}" ]; then
				NewSize=`du -h "$DEST/$filename.${DEST_EXT}" |cut -f1`
				NewSizeK=`du "$DEST/$filename.${DEST_EXT}" |cut -f1`
				NewLength=`avconv -i "$DEST/$filename.${DEST_EXT}" 2>&1 | grep 'Duration' | awk '{print $2}' | sed s/,//`
			else
				NewSize=0
				NewSizeK=0
			fi

			SizeChange=$(($NewSizeK * 100 / $OriginalSizeK ))
			LogAndEcho "Encoding took: `ShowTime $RunTime`"
			LogAndEcho "Encoded File Size: $NewSize ($SizeChange)"
			MaxSize=$(($OriginalSizeK * 8 / 10))

			if [[ $NewSizeK -eq 0 ]]; then
				LogAndEcho "File not created"
			elif [[ "$NewLength" = "$OriginalLength"  ]]; then
				LogAndEcho "Length Does Not Match"
			elif [[ $NewSizeK -gt $MaxSize ]]; then
				LogAndEcho "File is larger"
				#rm "$DEST/$filename.${DEST_EXT}"
			else
				LogAndEcho "Trashing: $FILE"
				gvfs-trash "$FILE"
				LogAndEcho "Moving To: ${FILE_DIR}"
				mv "$DEST/$filename.${DEST_EXT}" "${FILE_DIR}"

				push "Convert" "Done Reduced By: $SizeChange" -2

				
				#mv "$DEST/$filename.${DEST_EXT}" "$DEST/$filename.$DEST_EXT"
				#mv "$DEST/$filename.${DEST_EXT}" "$SRC/$filename.$DEST_EXT"
			fi

		else
			LogAndEcho "File is already h.265: Skipping"
		fi
done
push "convert" "done"
IFS="$OIFS"



