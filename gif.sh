#!/bin/sh
fps=10
dir=$1

#ffmpeg -ss 48:00 -i highlander.mp4 -t 20 -vf scale=420:-1 -f image2 -r $fps ss/%03d.png
ffmpeg -i $dir/%03d.png -vf "palettegen" -y $dir/pal.png
ffmpeg -framerate $fps -i $dir/%03d.png -i $dir/pal.png -lavfi "fps=$fps [x]; [x][1:v] paletteuse" -y $dir/out.gif
