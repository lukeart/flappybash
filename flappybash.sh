#!/bin/bash

IFS=''
echo -en "\e[?25l"
_STTY=$(stty -g)

FB_WIDTH=$(tput cols)
FB_HEIGHT=$(tput lines)

GAP_SIZE=3
MIN_WALL_HEIGHT=2

FPS=10
TIMING=`bc -l <<< "1/$FPS"`

FB_POS_Y=FB_HEIGHT/2
FB_POS_X=4
WALL_POS_Y=0
WALL_POS_X=10

function at_exit() {
	trap : ALRM # disable interupt

	echo -en "\e[?9l"          # Turn off mouse reading
	echo -en "\e[?12l\e[?25h"  # Turn on cursor
	stty "$_STTY"            # reinitialize terminal settings
	tput sgr0
	clear
}

function draw_area() {
	clear

	c="*"
	echo -en "\E[$FB_POS_Y;${FB_POS_X}f$c"
	
	c="|"
	Y=1
	while [ $Y -le $WALL_POS_Y ]; do
		echo -en "\E[$Y;${WALL_POS_X}f$c"
		let Y++
	done
	Y=$(($WALL_POS_Y+GAP_SIZE+1))
	while [ $Y -le $(($FB_HEIGHT-1)) ]; do
		echo -en "\E[$Y;${WALL_POS_X}f$c"
		let Y++
	done
}


function create_wall() {
	WALL_POS_Y=$(($RANDOM%(FB_HEIGHT-MIN_WALL_HEIGHT-MIN_WALL_HEIGHT-GAP_SIZE)+MIN_WALL_HEIGHT))
	WALL_POS_X=$(($FB_WIDTH-5))
}

function update () {
	
	WALL_POS_X=$[WALL_POS_X-1]
	if [ $WALL_POS_X -eq 0 ]; then
		create_wall
	fi
	
	if [ $WALL_POS_X -eq $FB_POS_X ]; then
		if [ $WALL_POS_Y -ge $FB_POS_Y ] || [ $(($WALL_POS_Y+$GAP_SIZE+1)) -le $FB_POS_Y ]; then
			exit
		fi
	fi
	
	FB_POS_Y=$[FB_POS_Y+1]
    if [ $FB_POS_Y -ge $FB_HEIGHT ] || [ $(($FB_POS_Y+100)) -le 100 ]]; then
		exit
	fi
	
}

function move() {

	( sleep $TIMING; kill -ALRM $$ ) &

	case "$KEY" in
		' ') FB_POS_Y=$[FB_POS_Y-2] ;;
	esac
	KEY=

	update
	draw_area
}

function new_level() {
	create_wall
	draw_area
	KEY='' 
	trap move ALRM
}

exec 2>/dev/null
trap at_exit ERR EXIT 

new_level
move
while :
do
	read -rsn1 KEY
done
