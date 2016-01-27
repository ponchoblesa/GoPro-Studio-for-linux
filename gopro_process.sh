#!/bin/bash
set -e

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
	if [ -e $(eval echo G*.JPG | head -n1 | awk '{print $1;}') ]; then
		eval $1=`ls G*.JPG | wc -l`
	fi
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

	for var in "$@";
	do
		if [[ i -gt 0 ]]; then
			touch -r "$file_source" "$var"
		fi
	    i=$[$i +1]
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


### PROCESS COLLAGE #####


# $1=TimeLapseNumber $2=Pictures1 $3=Pictures2
complex_montage () {
	local arguments="-border 2x2 -background black +polaroid -resize 75% -geometry -60-60 -tile x6"
	local picture_pattern2=$(eval echo $3 | head -n1 | awk '{print $1;}')
	local output="TL$1_collage.jpg"
	local outputbig="TL$1_collage_big.jpg"
	
	if ! [ -e $output ]; then
		echo "Adding $output"
		eval montage "$2" "$arguments" "$output" &
	fi

	if [ -e $picture_pattern2 ]; then
		if ! [ -e $outputbig ]; then
			echo "Adding TL$1_collage_big.jpg"
			eval montage "$2" "$3" "$arguments" "$outputbig" &
		fi
	fi

	wait

	echo "Finished custome collage"
}

# $1=TimeLapseNumber $2=Pictures1 $3=Pictures2
simple_montage () {
	local picture_pattern2=$(eval echo $3 | head -n1 | awk '{print $1;}')
	local output="TL$1_collage_simple.jpg"
	local outputbig="TL$1_collage_simple_big.jpg"

	if ! [ -e $output ]; then
		echo "Adding $output"
		eval montage "$2" "$output" &
	fi

	if [ -e $picture_pattern2 ]; then
		if ! [ -e $outputbig ]; then
			echo "Adding $outputbig"
			eval montage "$2" "$3" "$outputbig" &
		fi		
	fi

	wait

	echo "Finished simple collage"
}

# $1=TimeLapseNumber $2=Pictures1 $3=Pictures2
process_collage () {
	local picture_pattern1=$(eval echo $2 | head -n1 | awk '{print $1;}')
	local declare result=()

	if [ -e $picture_pattern1 ]; then
		complex_montage "$1" "$2" "$3" &
		simple_montage "$1" "$2" "$3" &

		wait
		
		result+=($(eval echo *collage*.jpg))
		set_date_of_file "$2" "${result[@]}"
		eval echo "*collage*.jpg created"
	fi
}


##### VIDEO #######


is_timelapse_video() {
	if [[ $1 == *FPS* ]]; then
		return 0
	else
		return 1
	fi
}

# $1=Source $2=Target
compress_video () {
	local handbrake_opts="-e x264  -q 20.0 -r 30 --pfr  -a 1,1 -E ffaac -B 160,160 -6 dpl2,none -R Auto,Auto -D 0.0,0.0 --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 -f mp4 --loose-anamorphic --modulus 2 -m --x264-preset fast --h264-profile baseline --h264-level 3.0"
	local video_dim="-X 1366 -Y 768"
	local pid

	if "$VIDEO_DEVICE_OPTIMIZED"; then
		video_dim="-X 1024 -Y 576"
	fi

	if ! [ -e ./temp/comp_"$1" ]; then
		eval HandBrakeCLI -i "$1" -o "$2" "$handbrake_opts" "$video_dim"
		touch -r "$1" "$2"
	fi
}

# $1=Source $2=Target
unify_fps_sound () {
	if ! [ -e "$2" ]; then
		ffmpeg -f lavfi -i anullsrc=r=48000 -i "$1" -shortest -r 59.940 -y "$2"
		touch -r "$1" "$2"
	fi
}

# $1=TimelapseVideo
preprocess_timelapse_video () {
	if ! [ -e "./temp/comp_$1" ]; then
		unify_fps_sound "$1" "./temp/fs_$1"
		compress_video "./temp/fs_$1" "./temp/comp_$1"
		rm "./temp/fs_$1"
	fi
}

process_videos () {
	local videos=($(eval ls *4 -1tr))
	get_date "${videos[0]}"

	if ! [ -e "$DATE_RETURN".mp4 ]; then
		mkdir -p temp
	
		for video in "${videos[@]}"; do
			if is_timelapse_video "$video"; then
				preprocess_timelapse_video "$video" &
			else
				compress_video "$video" "./temp/comp_$video" &
			fi
		done

		wait

		if [[ "${#videos[@]}" -gt 1 ]]; then
			for f in $(eval ls ./temp/comp_* -1tr); do echo "file '$f'" >> files.txt; done
			ffmpeg -f concat -i files.txt -c copy "$DATE_RETURN".mp4
			touch -r "${videos[0]}" "$DATE_RETURN".mp4
			rm files.txt
		else
			cp "./temp/comp_${videos[0]}" "$DATE_RETURN".mp4
		fi

		rm -r temp
	fi

	echo "Merged and/or compressed ${videos[@]} in $DATE_RETURN".mp4
}

#### FISHEYE PHOTOS ###

# $1=SourceFolder $2=DestFolder
set_date_to_edited_photos () {
	local declare pictures_list=()

	cd "$1"
	pictures_list+=($(ls GOPR*.JPG | sort | uniq))

	for i in "${pictures_list[@]}"; do
		set_date_of_file "$i" "$2/$i"
	done
}


### MAIN ###

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
						process_collage "$tl_num" "G*000.JPG" "G*500.JPG" &
						blackup_collage_photos "G*000.JPG" "G*500.JPG"
					fi
				else
					if "$COLLAGE"; then
						echo "Doing collage for more than 100 pictures..."
						process_collage "$tl_num" "G*00.JPG" "G*50.JPG" &
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
					process_collage "$tl_num" "G*0.JPG" "G*5.JPG" &
					blackup_collage_photos "G*0.JPG" "G*5.JPG"
				fi
			fi

			if "$TIMELAPSE"; then
				ls G*.JPG -1tr | sort > gopro.txt
				if ! [ -e "$tl_num"_FPS"$FPS_SLOW".mp4 ]; then
					mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=1920:1080 -mf type=jpeg:fps="$FPS_SLOW" mf://@gopro.txt -o "$tl_num"_FPS"$FPS_SLOW".mp4 &
				fi
				if ! [ -e "$tl_num"_FPS"$FPS_FAST".mp4 ]; then
					mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 -vf scale=1920:1080 -mf type=jpeg:fps="$FPS_FAST" mf://@gopro.txt -o "$tl_num"_FPS"$FPS_FAST".mp4 &
				fi

				wait

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

