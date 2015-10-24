#!/bin/bash

MEDIA_DIR="/media/poncho/Elements/GoPro/2015-*"

COLLAGE=true
FISHEYE=true

TIMELAPSE=true
DEFAULT_FPS=true
FPS_SLOW=0
FPS_FAST=0


declare -a FOLDERS_LIST_RETURN=()

# $1=DIR
get_folders_list() {
	FOLDERS_LIST_RETURN=()
	FOLDERS_LIST_RETURN+=($(eval ls -d "$1"))
}

# $1=Return value
count_files() {
	eval $1=`ls G*.JPG | wc -l`
}

# $1=Folder
is_timelapse() {
	if [[ $1 == *Timelapse* ]]; then
		return 0
	else
		return 1
	fi
}

# $1=Folder
is_video() {
	if [[ $1 == *Videos* ]]; then
		return 0
	else
		return 1
	fi
}

# $1=Folder
is_photo() {
	if [[ $1 == *Photos* ]]; then
		return 0
	else
		return 1
	fi
}

# $1=Source $2=Target [$3=Target ...]
set_date_of_file() {

	local i=0
	local file_source=$(eval echo "$1" | head -n1 | awk '{print $1;}')

	for var in "$@"
	do
		if [[ i -gt 0 ]]; then
			touch -r "$file_source" "$var"
		fi
	    ((i++))
	done
}

# $1=TimeLapseNumber $2=Pictures1 $3=Pictures2
process_collage () {

	local picture_pattern1=$(eval echo $2 | head -n1 | awk '{print $1;}')
	local picture_pattern2=$(eval echo $3 | head -n1 | awk '{print $1;}')
	if [ -e $picture_pattern1 ]; then

		eval montage "$2" -border 2x2 -background black +polaroid -resize 75% -geometry -60-60 -tile x6 TL"$1"_collage.jpg
		echo TL"$1"_collage.jpg saved
		eval montage "$2" TL"$1"_collage_simple.jpg
		echo TL"$1"_collage_simple.jpg saved
		
		if [ -e $picture_pattern2 ]; then
			eval montage "$2" "$3" -border 2x2 -background black +polaroid -resize 75% -geometry -60-60 -tile x6 TL"$1"_collage_big.jpg
			echo TL"$1"_collage_big.jpg saved		
			eval montage "$2" "$3" TL"$1"_collage_simple_big.jpg
			echo TL"$1"_collage_simple_big.jpg saved

			set_date_of_file "$2" TL"$1"_collage.jpg TL"$1"_collage_big.jpg TL"$1"_collage_simple.jpg TL"$1"_collage_simple_big.jpg
		else
			set_date_of_file "$2" TL"$1"_collage.jpg TL"$1"_collage_simple.jpg
		fi
		
		echo "All collages finished"
	fi

}

# $1=SourceFolder $2=DestFolder
set_date_to_edited_photos () {
	local declare pictures_list=()

	cd "$1"
	pictures_list+=($(ls GOPR*.JPG | sort | uniq))

	for i in "${pictures_list[@]}"; do
		set_date_of_file "$i" "$2/$i"
	done
}

get_folders_list "$MEDIA_DIR"
first_level=("${FOLDERS_LIST_RETURN[@]}")

for i in "${first_level[@]}"; do
	echo "Processing $i"
	get_folders_list "$i/*"
	second_level=("${FOLDERS_LIST_RETURN[@]}")

	for j in "${second_level[@]}"; do
		echo "Reading folder $j"

		if is_timelapse "$j"; then
			cd "$j"
			count_files files_num
			tl_num=`echo "$(basename $j)" | sed 's/^.\{10\}\(.\{3\}\).*/\1/'`
			echo "Timelapse $tl_num"

			if [[ "$files_num" -gt 100 ]]; then
				if "$DEFAULT_FPS"; then
					FPS_SLOW=10
					FPS_FAST=20
				fi

				if [[ "$files_num" -gt 1000 ]]; then
					if "$COLLAGE"; then
						echo "Doing collage for more than 1000 pictures..."
						process_collage "$tl_num" "G*000.JPG" "G*500.JPG"
					fi
				else
					if "$COLLAGE"; then
						echo "Doing collage for more than 100 pictures..."
						process_collage "$tl_num" "G*00.JPG" "G*50.JPG"
					fi
				fi
				
			else

				if "$DEFAULT_FPS"; then
					FPS_SLOW=3
					FPS_FAST=5
				fi
				if "$COLLAGE"; then
					echo "Doing collage for less than 100 pictures..."
					process_collage "$tl_num" "G*0.JPG" "G*5.JPG"
				fi
			fi

			if "$TIMELAPSE"; then
				ls G*.JPG -1tr | sort > gopro.txt
				mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=1920:1080 -mf type=jpeg:fps="$FPS_SLOW" mf://@gopro.txt -o "$tl_num"_FPS"$FPS_SLOW".mp4
				mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=1920:1080 -mf type=jpeg:fps="$FPS_FAST" mf://@gopro.txt -o "$tl_num"_FPS"$FPS_FAST".mp4
				set_date_of_file "G*.JPG" "$tl_num"_FPS"$FPS_SLOW".mp4 "$tl_num"_FPS"$FPS_FAST".mp4
				echo "TIMELAPSE"
				rm gopro.txt
			fi
		fi

		if is_photo "$j"; then
			if "$FISHEYE"; then
				cd "$j"
				mkdir -p without_fisheye
				cp -n ./*.JPG ./without_fisheye
				cd ./without_fisheye
				echo "Removing fisheye..."
				mogrify -distort barrel "0 0 -0.3" *.JPG
				set_date_to_edited_photos "$j" "$j/without_fisheye"
			fi			
		fi	
	done
done

