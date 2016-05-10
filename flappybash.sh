#!/bin/bash

IFS=''
echo -en "\e[?25l"
_STTY=$(stty -g)

FB_WIDTH=$(tput cols)
FB_HEIGHT=$(tput lines)

GAP_SIZE=5
MIN_WALL_HEIGHT=2
WALL_DISTANCE=10
NUM_WALLS=`expr $FB_WIDTH / $WALL_DISTANCE`
echo $FB_WIDTH $WALL_DISTANCE $NUM_WALLS
read


FPS=10
TIMING=`bc -l <<< "1/$FPS"`

FB_POS_Y=FB_HEIGHT/2
FB_POS_X=4
WALL_POS_Y=0
WALL_POS_X=10
WALL_Y=
WALL_X=

function at_exit() {
	trap : ALRM # disable interupt
	echo -en "\a"
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
	
	X=0;
	c="|"
	while [ $WALLS_X[$X] -le $FB_WIDTH ] || [ $X -le $NUM_WALLS ]; do
		Y=1
		while [ $Y -le $WALL_POS_Y ]; do
			echo -en "\E[$Y;${WALL_POS_X}f$c"
			Y=$[Y+1]
		done
		Y=$(($WALL_POS_Y+GAP_SIZE+1))
		while [ $Y -le $(($FB_HEIGHT-1)) ]; do
			echo -en "\E[$Y;${WALL_POS_X}f$c"
			Y=$[Y+1]
		done
		X=$[X+1]
	done
}


function create_wall() {
	
	while [ ${#WALLS_Y[@]} -le $NUM_WALLS ]; do
		LAST=${#WALLS_Y[@]}
		WALLS_Y[$LAST]=$(($RANDOM%($FB_HEIGHT-$MIN_WALL_HEIGHT-$MIN_WALL_HEIGHT-$GAP_SIZE)+$MIN_WALL_HEIGHT))
		WALLS_X[$LAST]=$((15+10*$LAST))
	done
	
	WALL_POS_Y=${WALLS_Y[0]}
	WALL_POS_X=${WALLS_X[0]}
}

function update () {
	
	WALL_POS_X=$[WALL_POS_X-1]
	if [ $WALL_POS_X -eq 0 ]; then
		WALLS_X=("${WALLS_X[@]:1}")
		WALLS_Y=("${WALLS_Y[@]:1}")
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
		' ') if [ $FB_POS_Y -le 2 ]; then
				exit
			fi
			FB_POS_Y=$[FB_POS_Y-2] ;;
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
