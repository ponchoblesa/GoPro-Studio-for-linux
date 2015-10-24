#!/bin/bash

CAMERA_DIR="/media/user/MyCard"
DEST_DIR="~/GoPro"
OVERWRITE_FILES=false

DATE="*" #Date pattern yyyy-mm-dd. Exp1: 2015-10-15 (Only files of that day). Exp2: 2015-11-* (All the files of November). Exp3: * (All the files regardless the date)
GET_TIMELAPSE=true
GET_PHOTOS=true
GET_VIDEOS=true

DATE_RETURN=""
declare -a LAPSES_RETURN=()
declare -a FOLDERS_LIST_RETURN=()
declare -a PICTURES_LIST_RETURN=()
declare -a VIDEO_LIST_RETURN=()
declare -a CHAPTER_RETURN=()

# $1=FILE
get_date() {
	DATE_RETURN=$(date -r $1 +%F)
}

# $1=DIR
get_lapse_num() {
	LAPSES_RETURN=()
	cd "$1"

	local lapse_pattern=$(echo ./G*.JPG | head -n1 | awk '{print $1;}')
	if [ -e $lapse_pattern ]; then
		LAPSES_RETURN+=($(ls G*.JPG | sed 's/^.\{1\}\(.\{3\}\).*/\1/' | sed 's/[^0-9]*//g' | sort | uniq))
	fi
}

# $1=DIR
get_pictures_list() {
	PICTURES_LIST_RETURN=()
	cd "$1"
	
	local picture_pattern=$(echo ./GOPR*.JPG | head -n1 | awk '{print $1;}')
	if [ -e $picture_pattern ]; then
		PICTURES_LIST_RETURN+=($(ls GOPR*.JPG | sort | uniq))
	fi
}

# $1=DIR
get_video_list() {
	VIDEO_LIST_RETURN=()
	cd "$1"

	local video_pattern=$(echo ./GOPR*.MP4 | head -n1 | awk '{print $1;}')
	if [ -e $video_pattern ]; then
		VIDEO_LIST_RETURN+=($(ls GOPR*.MP4 | sort | uniq))
	fi
}

# $1=DIR
get_chapter_video_num() {
	CHAPTER_RETURN=()
	cd "$1"

	local chapter_pattern=$(echo ./GP*.MP4 | head -n1 | awk '{print $1;}')
	if [ -e $chapter_pattern ]; then
		CHAPTER_RETURN+=($(ls GP*.MP4 | sed 's/^.\{4\}\(.\{4\}\).*/\1/' | sed 's/[^0-9]*//g' | sort | uniq))
	fi	
}

# $1=DIR
get_folders_list() {
	FOLDERS_LIST_RETURN=()

	local folder_match=$(eval echo "$1" | head -n1 | awk '{print $1;}')
	if [ -d $folder_match ]; then
		FOLDERS_LIST_RETURN+=($(eval ls -d "$1"))
	fi
}

# $1=SOURCE $2=DEST
copy_files() {
	if [ "$OVERWRITE_FILES" = true ]; then
		yes | eval cp -rf "$1" "$2"
	else
		eval cp -n "$1" "$2"
	fi
}

# $1=SourceFolder $2=DestFolder $3=Pattern
set_date_to_files () {
	local declare file_list=()

	cd "$1"
	file_list+=($(eval ls "$3" | sort | uniq))

	for i in "${file_list[@]}"; do
		touch -r "$i" "$2/$i"
	done
}

######## REFACTOR ######

process_timelapse_files() {
	get_lapse_num "./"
	for k in "${LAPSES_RETURN[@]}";
	do
		get_date G"$k"*.JPG
		
		if [[ $DATE_RETURN == $DATE ]]; then
			echo "Getting Timelapse $k pictures of $DATE_RETURN"
			mkdir -p "$DEST_DIR/$DATE_RETURN"
			mkdir -p "$DEST_DIR/$DATE_RETURN/Timelapse_$k"
			echo "Copying files from G$k*.JPG to $DEST_DIR/$DATE_RETURN/Timelapse_$k"
			copy_files "G$k*.JPG" "$DEST_DIR/$DATE_RETURN/Timelapse_$k"
			set_date_to_files "./" "$DEST_DIR/$DATE_RETURN/Timelapse_$k" "G$k*.JPG"
		fi		
		
	done
}

process_photo_files() {
	get_pictures_list "./"
	for k in "${PICTURES_LIST_RETURN[@]}";
	do
		get_date "$k"
		if [[ $DATE_RETURN == $DATE ]]; then
			mkdir -p "$DEST_DIR/$DATE_RETURN"
			mkdir -p "$DEST_DIR/$DATE_RETURN/Photos"			
			echo "Copying picture $k of $DATE_RETURN to $DEST_DIR/$DATE_RETURN/Photos"
			copy_files "$k" "$DEST_DIR/$DATE_RETURN/Photos"
			set_date_to_files "./" "$DEST_DIR/$DATE_RETURN/Photos" "$k"
		fi
	done
}

process_video_files() {
	get_video_list "./"
	for k in "${VIDEO_LIST_RETURN[@]}";
	do
		get_date "$k"
		if [[ $DATE_RETURN == $DATE ]]; then
			mkdir -p "$DEST_DIR/$DATE_RETURN"
			mkdir -p "$DEST_DIR/$DATE_RETURN/Videos"		
			echo "Copying video $k of $DATE_RETURN to $DEST_DIR/$DATE_RETURN/Videos"
			copy_files "$k" "$DEST_DIR/$DATE_RETURN/Videos"
			set_date_to_files "./" "$DEST_DIR/$DATE_RETURN/Videos" "$k"
		fi
	done
}

process_chaptered_video_files() {
	get_chapter_video_num "./"
	for k in "${CHAPTER_RETURN[@]}";
	do
		get_date GP*"$k".MP4
		if [[ $DATE_RETURN == $DATE ]]; then
			echo "Getting chapters of video $k of $DATE_RETURN"
			mkdir -p "$DEST_DIR/$DATE_RETURN"
			mkdir -p "$DEST_DIR/$DATE_RETURN/Videos"
			mkdir -p "$DEST_DIR/$DATE_RETURN/Videos/$k"	
			echo "Copying files from GP*$k.MP4 to $DEST_DIR/$DATE_RETURN/Videos/$k"
			copy_files "GP*$k.MP4" "$DEST_DIR/$DATE_RETURN/Videos/$k"
			set_date_to_files "./" "$DEST_DIR/$DATE_RETURN/Videos/$k" "GP*$k.MP4"
		fi
	done
}

######## MAIN ######

mkdir -p $DEST_DIR
get_folders_list "$CAMERA_DIR/*"
first_level=("${FOLDERS_LIST_RETURN[@]}")

for i in "${first_level[@]}"; do
	get_folders_list "$i/*"
	second_level=("${FOLDERS_LIST_RETURN[@]}")

	#Foreach folder with media files
	for j in "${second_level[@]}"; do
		echo "Checking files in $j"
		cd "$j"

		##Timelapse pictures
		if [ "$GET_TIMELAPSE" = true ]; then
			process_timelapse_files
		fi

		##Single pictures
		if [ "$GET_PHOTOS" = true ]; then
			echo "Checking pictures from $j"
			process_photo_files
		fi

		if [ "$GET_VIDEOS" = true ]; then
			##Single videos
			echo "Checking videos from $j"
			process_video_files

			##Chaptered Video
			process_chaptered_video_files
		fi			
	done
done