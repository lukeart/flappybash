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
echo -n > flappydebug
read


FPS=10
TIMING=`bc -l <<< "1/$FPS"`

FB_POS_Y=$[FB_HEIGHT/2]
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
	# Loop through all walls, until they won't fit on the screen
	# TODO: improve loop conditions
	while [ ${WALLS_X[$X]} -le $FB_WIDTH ] && [ $X -le $NUM_WALLS ]; do
		WY=${WALLS_Y[$X]}
		WX=${WALLS_X[$X]}
		
		# Upper part of the wall
		Y=1
		while [ $Y -le $WY ]; do
			echo -en "\E[$Y;${WX}f$c"
			Y=$[Y+1]
		done
		
		# Buttom part of the wall
		Y=$[WY+GAP_SIZE+1]
		while [ $Y -le $(($FB_HEIGHT-1)) ]; do
			echo -en "\E[$Y;${WX}f$c"
			Y=$[Y+1]
		done
		X=$[X+1]
	done
}


function create_wall() {
	# Loop until there are $NUM_WALLS+1 walls
	# At startup this populated the empty arrays, since ${#WALLS_Y[@]} won't fail but returns 0
	# Can't use [-1], cause it will fail on an empty array 
	while [ ${#WALLS_Y[@]} -le $NUM_WALLS ]; do
		LAST=${#WALLS_Y[@]}
		WALLS_Y[$LAST]=$(($RANDOM%($FB_HEIGHT-$MIN_WALL_HEIGHT-$MIN_WALL_HEIGHT-$GAP_SIZE)+$MIN_WALL_HEIGHT))
		# Take the furthest wall and add 10
		WALLS_X[$LAST]=$[${WALLS_X[$[LAST-1]]}+$WALL_DISTANCE]
	done
	
	# WALLS_POX_Y/X will contain the only relevant wall coordinates
	WALL_POS_Y=${WALLS_Y[0]}
	WALL_POS_X=${WALLS_X[0]}
}

function update () {
	
	# Move all walls in the array forward
	X=0;
	while [ $X -lt ${#WALLS_X[@]} ]; do
		WALLS_X[$X]=$[${WALLS_X[$X]}-1]
		X=$[X+1]
	done
	
	# As well as the closest one
	WALL_POS_X=$[WALL_POS_X-1]
	
	# If the closest one has left the screen, shift the array.
	if [ $WALL_POS_X -eq 0 ]; then
		WALLS_X=("${WALLS_X[@]:1}")
		WALLS_Y=("${WALLS_Y[@]:1}")
		# TODO: WALL_POS_Y/X needs to be updates, preferrably only once
	fi
	
	# If there's enough space for a new wall, create it
	if [ $((${WALLS_X[-1]}+$WALL_DISTANCE)) -le $FB_WIDTH ]; then
		create_wall
	fi

	# Wall collision
	if [ $WALL_POS_X -eq $FB_POS_X ]; then
		if [ $WALL_POS_Y -ge $FB_POS_Y ] || [ $[WALL_POS_Y+GAP_SIZE+1] -le $FB_POS_Y ]; then
			exit
		fi
	fi
	
	# Dropped off the bottom
	# TODO: Hitting the ceiling		
    if [ $FB_POS_Y -ge $FB_HEIGHT ]; then
		exit
	fi
	
	# 'Gravity'
	FB_POS_Y=$[FB_POS_Y+1]
}

function move() {
	# Spawn a sub process that will call this function after $TIMING seconds
	( sleep $TIMING; kill -ALRM $$ ) &

	case "$KEY" in
			# Flap
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

# Hook Ctrl-C to function 'at_exit'
trap at_exit ERR EXIT 

new_level
move
while :
do
	read -rsn1 KEY
done
