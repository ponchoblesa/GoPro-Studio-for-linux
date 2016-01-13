#!/bin/bash

MEDIA_DIR="~/GoPro/*"

COLLAGE=true
FISHEYE=true
VIDEO=true

VIDEO_DEVICE_OPTIMIZED=true

TIMELAPSE=true
DEFAULT_FPS=true
FPS_SLOW=0
FPS_FAST=0

DATE_RETURN=""

declare -a FOLDERS_LIST_RETURN=()

# $1=FILE
get_date() {
	DATE_RETURN=$(date -r $1 +%F)
}

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

# $1=Pictures1 $2=Pictures2
blackup_collage_photos () {

	local picture_pattern1=$(eval echo $1 | head -n1 | awk '{print $1;}')
	local picture_pattern2=$(eval echo $2 | head -n1 | awk '{print $1;}')
	local declare pictures_list=()

	if [ -e $picture_pattern1 ]; then

		mkdir -p collage_photos
		eval cp -n "./$1" ./collage_photos
		eval echo "Photos blackup: $1"
		pictures_list+=($(eval ls $1 | sort | uniq))
		
		if [ -e $picture_pattern2 ]; then
			eval cp -n "./$2" ./collage_photos
			eval echo "Photos blackup 2: $2"
			pictures_list+=($(eval ls "$2" | sort | uniq))
		fi

		for i in "${pictures_list[@]}"; do
			set_date_of_file "./$i" "./collage_photos/$i"
		done

		echo "Copied collage pictures in 'collage_photos'"
	fi
}

# $1=TimeLapseNumber $2=Pictures1 $3=Pictures2
process_collage () {

	local picture_pattern1=$(eval echo $2 | head -n1 | awk '{print $1;}')
	local picture_pattern2=$(eval echo $3 | head -n1 | awk '{print $1;}')
	if [ -e $picture_pattern1 ]; then

		if ! [ -e TL"$1"_collage.jpg ]; then
			eval montage "$2" -border 2x2 -background black +polaroid -resize 75% -geometry -60-60 -tile x6 TL"$1"_collage.jpg
			echo TL"$1"_collage.jpg saved
		fi

		if ! [ -e TL"$1"_collage_simple.jpg ]; then
			eval montage "$2" TL"$1"_collage_simple.jpg
			echo TL"$1"_collage_simple.jpg saved
		fi

		if [ -e $picture_pattern2 ]; then
			
			if ! [ -e TL"$1"_collage_big.jpg ]; then
				eval montage "$2" "$3" -border 2x2 -background black +polaroid -resize 75% -geometry -60-60 -tile x6 TL"$1"_collage_big.jpg
				echo TL"$1"_collage_big.jpg saved
			fi
			
			if ! [ -e TL"$1"_collage_simple_big.jpg ]; then
				eval montage "$2" "$3" TL"$1"_collage_simple_big.jpg
				echo TL"$1"_collage_simple_big.jpg saved
			fi

			set_date_of_file "$2" TL"$1"_collage.jpg TL"$1"_collage_big.jpg TL"$1"_collage_simple.jpg TL"$1"_collage_simple_big.jpg
		else
			set_date_of_file "$2" TL"$1"_collage.jpg TL"$1"_collage_simple.jpg
		fi
		
		echo "All collages finished"
	fi

}

process_videos () {
	local videos=($(ls G*.MP4 -1tr))
	local first_video=$(echo $videos | head -n1 | awk '{print $1;}')
	local videos_quantity=$(ls G*.MP4 | wc -l)
	local handbrake_opts="-e x264  -q 20.0 -r 30 --pfr  -a 1,1 -E ffaac -B 160,160 -6 dpl2,none -R Auto,Auto -D 0.0,0.0 --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 -f mp4 --loose-anamorphic --modulus 2 -m --x264-preset fast --h264-profile baseline --h264-level 3.0"
	local video_dim="-X 1365 -Y 768"
	get_date "$first_video"

	if "$VIDEO_DEVICE_OPTIMIZED"; then
		video_dim="-X 720 -Y 576"
	fi

	if ! [ -e "$DATE_RETURN".mp4 ]; then
		echo 'Merging '"${videos[@]}"' into '"$DATE_RETURN"'.mp4'
		if [[ "$videos_quantity" -gt 1 ]]; then
			mencoder -ovc copy -oac pcm "${videos[@]}" -o "$DATE_RETURN"_merge_big.mp4
			eval HandBrakeCLI -i "$DATE_RETURN"_merge_big.mp4 -o "$DATE_RETURN".mp4 "$handbrake_opts" "$video_dim"
			rm "$DATE_RETURN"_merge_big.mp4
		else
			
			eval HandBrakeCLI -i "$first_video" -o "$DATE_RETURN".mp4 "$handbrake_opts" "$video_dim"
			HandBrakeCLI -i "$first_video" -o "$DATE_RETURN"_merge.mp4 "$handbrake_opts $video_dim"
		fi

		touch -r "$first_video" "$DATE_RETURN".mp4
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
						blackup_collage_photos "G*000.JPG" "G*500.JPG"
					fi
				else
					if "$COLLAGE"; then
						echo "Doing collage for more than 100 pictures..."
						process_collage "$tl_num" "G*00.JPG" "G*50.JPG"
						blackup_collage_photos "G*00.JPG" "G*50.JPG"
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
					blackup_collage_photos "G*0.JPG" "G*5.JPG"
				fi
			fi

			if "$TIMELAPSE"; then
				ls G*.JPG -1tr | sort > gopro.txt
				if ! [ -e "$tl_num"_FPS"$FPS_SLOW".mp4 ]; then
					mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=1920:1080 -mf type=jpeg:fps="$FPS_SLOW" mf://@gopro.txt -o "$tl_num"_FPS"$FPS_SLOW".mp4
				fi
				if ! [ -e "$tl_num"_FPS"$FPS_FAST".mp4 ]; then
					mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=1920:1080 -mf type=jpeg:fps="$FPS_FAST" mf://@gopro.txt -o "$tl_num"_FPS"$FPS_FAST".mp4
				fi
				set_date_of_file "G*.JPG" "$tl_num"_FPS"$FPS_SLOW".mp4 "$tl_num"_FPS"$FPS_FAST".mp4
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

		if is_video "$j"; then
			if "$VIDEO"; then
				cd "$j"
				process_videos
			fi
		fi

	done
done

