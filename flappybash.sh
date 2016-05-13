#!/bin/bash

IFS=''
echo -en "\e[?25l"
_STTY=$(stty -g)

FB_WIDTH=$(tput cols)
FB_HEIGHT=$(tput lines)

GAP_SIZE=`bc <<< $FB_HEIGHT/3`
MIN_WALL_HEIGHT=2
WALL_DISTANCE=`bc <<< $FB_HEIGHT/1.5`
WALL_WIDTH=`bc <<< $WALL_DISTANCE/5`
#echo 1 $WALL_DISTANCE2
#WALL_DISTANCE=10
NUM_WALLS=`expr $FB_WIDTH / $WALL_DISTANCE`
FLAP_SPEED=`bc <<< $GAP_SIZE/2`
echo $FB_WIDTH $WALL_DISTANCE $NUM_WALLS
echo -n > flappydebug
read


#FPS=10
FPS=`bc <<< $FB_HEIGHT/1.5`
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
#	clear
	echo -e '\0033\0143'

	# Draw Flappy
	c="*"
	echo -en "\E[$FB_POS_Y;${FB_POS_X}f$c"
	
	Z=0;
	# Loop through all walls, until they won't fit on the screen
	# TODO: improve loop conditions
	while [ ${WALLS_X[$Z]} -le $FB_WIDTH ] && [ $Z -le $NUM_WALLS ]; do
		WY=${WALLS_Y[$Z]}
		WX=${WALLS_X[$Z]}
		
		# Upper part of the wall
		X=1
		while [ "$X" -le "$WALL_WIDTH" ]; do
			Y=1
			while [ $Y -le $WY ]; do
				if [ "$X" = 1 ] || [ "$X" = "$WALL_WIDTH" ]; then
					c="|"
					if [ "$Y" -eq "$WY" ]; then
						c="+"
					fi				
				else
					c=" "
					if [ "$Y" -eq "$WY" ]; then
						c="-"
					fi
				fi
				echo -en "\E[$Y;$[WX+X]f$c"
				Y=$[Y+1]
			done
			X=$[X+1]
		done
		# Buttom part of the wall
		X=1
		while [ "$X" -le "$WALL_WIDTH" ]; do
			Y=$[WY+GAP_SIZE+1]
			while [ $Y -le $(($FB_HEIGHT-1)) ]; do
				if [ "$X" = 1 ] || [ "$X" = "$WALL_WIDTH" ]; then
					c="|"
					if [ "$Y" -eq "$[WY+GAP_SIZE+1]" ]; then
						c="+"
					fi
				else
					c=" "
					if [ "$Y" -eq "$[WY+GAP_SIZE+1]" ]; then
						c="-"
					fi
				fi
				echo -en "\E[$Y;$[WX+X]f$c"
				Y=$[Y+1]
			done
			X=$[X+1]
		done
		Z=$[Z+1]
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
	
}

function update () {
	# 'Gravity'
	FB_POS_Y=$[FB_POS_Y+1]

	# Move all walls in the array forward
	X=0;
	while [ $X -lt ${#WALLS_X[@]} ]; do
		WALLS_X[$X]=$[${WALLS_X[$X]}-1]
		X=$[X+1]
	done
	
	# If the closest one has left the screen, shift the array.
	if [ ${WALLS_X[0]} -eq 0 ]; then
		WALLS_X=("${WALLS_X[@]:1}")
		WALLS_Y=("${WALLS_Y[@]:1}")
		# TODO: WALL_POS_Y/X needs to be updates, preferrably only once
	fi
	
	# If there's enough space for a new wall, create it
	if [ $((${WALLS_X[-1]}+$WALL_DISTANCE)) -le $FB_WIDTH ]; then
		create_wall
	fi

	# We'll check only the only relevant (first) wall coordinates
#	WALL_POS_Y=${WALLS_Y[0]}
#	WALL_POS_X=${WALLS_X[0]}
	
	# Wall collision
	if [ ${WALLS_X[0]} -le $FB_POS_X ] && [ $[${WALLS_X[0]}+WALL_WIDTH] -gt $FB_POS_X ]; then
		if [ ${WALLS_Y[0]} -ge $FB_POS_Y ] || [ $[${WALLS_Y[0]}+GAP_SIZE+1] -le $FB_POS_Y ]; then
			exit
		fi
	fi
	
	# Dropped off the bottom
	# TODO: Hitting the ceiling		
    if [ $FB_POS_Y -ge $FB_HEIGHT ]; then
		exit
	fi
	
}

function move() {
	# Spawn a sub process that will call this function after $TIMING seconds
	( sleep $TIMING; kill -ALRM $$ ) &

	case "$KEY" in
			# Flap
		' ') if [ $FB_POS_Y -le $FLAP_SPEED ]; then
				exit
			fi
			FB_POS_Y=$[FB_POS_Y-FLAP_SPEED] ;;
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
