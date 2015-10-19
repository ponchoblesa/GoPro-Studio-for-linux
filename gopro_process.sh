#!/bin/bash

MEDIA_DIR="/media/poncho/Elements/GoPro/2015-10-*"
DEFAULT_FPS=true


declare -a FOLDERS_LIST_RETURN=()
FPS_SLOW=0
FPS_FAST=0

# $1=DIR
get_folders_list() {
	FOLDERS_LIST_RETURN=()

	local folder_match=$(eval echo "$1" | head -n1 | awk '{print $1;}')
	if [ -d $folder_match ]; then
		FOLDERS_LIST_RETURN+=($(eval ls -d "$1"))
	fi
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

			else

				if "$DEFAULT_FPS"; then
					FPS_SLOW=3
					FPS_FAST=5
				fi
			fi

			ls G*.JPG -1tr | sort > gopro.txt
			mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=1920:1080 -mf type=jpeg:fps="$FPS_SLOW" mf://@gopro.txt -o "$tl_num"_FPS"$FPS_SLOW".mp4
			mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=1920:1080 -mf type=jpeg:fps="$FPS_FAST" mf://@gopro.txt -o "$tl_num"_FPS"$FPS_FAST".mp4
			rm gopro.txt
		fi

		if is_photo "$j"; then
			cd "$j"
			mkdir -p without_fisheye
			cp -n ./*.JPG ./without_fisheye
			cd ./without_fisheye
			echo "Removing fisheye..."
			mogrify -distort barrel "0 0 -0.3" *.JPG
		fi
	done
done

