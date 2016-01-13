# GoPro Studio for Linux

This repository contains some bash scripts to process your GoPro media files (.JPG .MP4). They are optimized for GoPro Hero 3+, but its parameters can be easily changed for your particular GoPro. The scripts works thanks to the [GoPro naming convention](http://gopro.com/support/articles/hero3-and-hero3-file-naming-convention).

Download the repository and start using it

   git clone https://github.com/ponchoblesa/GoPro-Studio-for-linux.git

## Import

Total unattended and customizable. Organize your files in your computer by date and type (video, chaptered video, timelapse photos and normal photos), like the GoPro Studio does. For each day, the script will create a folder and inside, will classify the files by type, including organizing the timelapses in different folders.

### Usage

Open the script and customize the vars:

    CAMERA_DIR="/media/user/MyCard" // The root folder where the memory card with the files is
    DEST_DIR="~/GoPro"                 // The path where to import the files
 
    OVERWRITE_FILES=false              // Clear what it does right?

	DATE="*" 						   // Date pattern yyyy-mm-dd.
										     Example1: 2015-10-15 (Only files of that day).
										     Example2: 2015-11-* (All the files of November).
										     Example3: * (All the files regardless the date)

	GET_TIMELAPSE=true                  // Set to false if you do not want to import a specific type of file
	GET_PHOTOS=true
	GET_VIDEOS=true

Then save it and execute it from terminal

    bash gopro_import.sh

## Process

Also total unattended and customizable. It will process you local GoPro files with some common features.

### Requirements

* [ImageMagick](http://www.imagemagick.org/script/index.php): sudo apt-get install imagemagick
* [MenCoder](https://help.ubuntu.com/community/MEncoder): sudo apt-get install mencoder
* [HandBrake CLI](https://handbrake.fr/downloads2.php): Download/Upgrade it from this repository:
		sudo apt-add-repository ppa:stebbins/handbrake-snapshots
		sudo apt-get update
		apt-get install --only-upgrade handbrake-cli

### Usage

Open the script and customize the vars:

	MEDIA_DIR="~/GoPro/2015-*"  // The folder that you want to process with date pattern yyyy-mm-dd.
								    Example1: ~/GoPro/2015-10-15 (Only files of that day).
									Example2: ~/GoPro/2015-11-* (All the files of November).
									Example3: ~/GoPro/* (All the files regardless the date)

	COLLAGE=true				// Set to false if you do not want to run a particular feature
	FISHEYE=true
	VIDEO=true

	VIDEO_DEVICE_OPTIMIZED=true
	
	TIMELAPSE=true
	DEFAULT_FPS=true			// Set it to false if you want to customize the frames per second
	FPS_SLOW=0						of the timelapse video. Then change the zero value for the two desired
	FPS_FAST=0						fps values for the videos.

Then save it and execute it from terminal

    bash gopro_process.sh

### Included Features

#### Timelapse

	TIMELAPSE=true

By default it will create two videos of two different speeds. If the timelapse is bigger than a hundred of photos, the speeds are 20fps and 10fps. Otherwise it will be 5fps and 3fps. If you want to change these values, you have to unlock the default fps var. For example, for a configuration of 13fps and 17fps, the initial variables are:

    DEFAULT_FPS=false
	FPS_SLOW=13
	FPS_FAST=17

#### Collage
	
	COLLAGE=true

With the pictures of the timelapse, it will create 4 collages of two different configuration, 2 of them big if there are many pictures.

#### Fish Eye Removing

    FISHEYE=true

It will create a folder inside the photos path with the edited pictures. The script is optimized for GoPro Hero3+. If you want to change these parameters, edit the line of the script with the desire parameters:

    mogrify -distort barrel "0 0 -0.3" *.JPG 

#### Video merger and compression

	VIDEO=true

It will merge in one all the videos of each day. The result will be a single file [date].mp4 with all the videos of these day in chronological order.

	VIDEO_DEVICE_OPTIMIZED=true

This video is compressed in order to get a lighter file with almost the same video quality. If the variable "VIDEO_DEVICE_OPTIMIZED" is true, it will also crop its resolution optimized for device, giving as a result an even lighter video which display perfectly in every device. Otherwise, the resolution will be bigger and optimized for big screens.

For compression is used a preset of Handbrake a bit modified. If you want to change this default behaviour, take a look to the [documentation of Handbrake CLI](https://trac.handbrake.fr/wiki/BuiltInPresets) and edit the variable $handbrake_opts of the script.

## Acknowledge

[KonradIT](https://gist.github.com/KonradIT/ee685aee15ba1c3c44b4)

## License

The MIT License (MIT)

Copyright (c) 2015 ponchoblesa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.