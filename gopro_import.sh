#!/bin/bash

CAMERA_DIR="/media/poncho/BF2F-7465"
DEST_DIR="/media/poncho/Elements/GoPro"
OVERWRITE_FILES=false


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


mkdir -p $DEST_DIR
get_folders_list "$CAMERA_DIR/*"
first_level=("${FOLDERS_LIST_RETURN[@]}")

for i in "${first_level[@]}";
	do
		get_folders_list "$CAMERA_DIR/$i/*"
		second_level=("${FOLDERS_LIST_RETURN[@]}")

		#Foreach folder with media files
		for j in "${second_level[@]}"; do
			echo "Getting files from dir $j...."			
			current_full_path="$CAMERA_DIR/$i$j"			
			cd "$current_full_path"
			echo "Working path $current_full_path"

			##Timelapse pictures
			get_lapse_num "./"
			for k in "${LAPSES_RETURN[@]}";
			do
				echo "Getting Timelapse $k pictures"

				get_date G"$k"*.JPG
				mkdir -p "$DEST_DIR/$DATE_RETURN"
				mkdir -p "$DEST_DIR/$DATE_RETURN/Timelapse_$k"
				
				echo "Copying files from G$k*.JPG to $DEST_DIR/$DATE_RETURN/Timelapse_$k"
				copy_files "G$k*.JPG" "$DEST_DIR/$DATE_RETURN/Timelapse_$k"
			done

			##Single pictures
			echo "Copying pictures from $current_full_path"
			get_pictures_list "./"
			for k in "${PICTURES_LIST_RETURN[@]}";
			do
				get_date "$k"
				mkdir -p "$DEST_DIR/$DATE_RETURN"
				mkdir -p "$DEST_DIR/$DATE_RETURN/Photos"
				
				echo "Copying picture $k to $DEST_DIR/$DATE_RETURN/Photos"
				copy_files "$k" "$DEST_DIR/$DATE_RETURN/Photos"
			done

			##Single videos
			echo "Copying videos from $current_full_path"
			get_video_list "./"
			for k in "${VIDEO_LIST_RETURN[@]}";
			do
				get_date "$k"
				mkdir -p "$DEST_DIR/$DATE_RETURN"
				mkdir -p "$DEST_DIR/$DATE_RETURN/Videos"
				
				echo "Copying video $k to $DEST_DIR/$DATE_RETURN/Videos"
				copy_files "$k" "$DEST_DIR/$DATE_RETURN/Videos"
			done

			##Chaptered Video
			get_chapter_video_num "./"
			for k in "${CHAPTER_RETURN[@]}";
			do
				echo "Getting chapters of video $k"

				get_date GP*"$k".MP4
				mkdir -p "$DEST_DIR/$DATE_RETURN"
				mkdir -p "$DEST_DIR/$DATE_RETURN/Videos"
				mkdir -p "$DEST_DIR/$DATE_RETURN/Videos/$k"
				
				echo "Copying files from GP*$k.MP4 to $DEST_DIR/$DATE_RETURN/Videos/$k"
				copy_files "GP*$k.MP4" "$DEST_DIR/$DATE_RETURN/Videos/$k"
			done

		done

done
