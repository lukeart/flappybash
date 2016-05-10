#!/bin/bash

IFS=''

FB_WIDTH=$(tput cols)
FB_HEIGHT=$(tput lines)

TIMING=0.1

GAP_SIZE=3
MIN_WALL_HEIGHT=2

declare -i FB_POS_Y=FB_HEIGHT/2
declare -i FB_POS_X=3
declare -i WALL_POS_Y=0
declare -i WALL_POS_X=10
declare -ri fps=60
declare -ri gravity_fps=10
declare -i score=0
declare -i last_update=0
declare -i gravity_last_update=0

function at_exit() {
	trap : ALRM # disable interupt

	printf "\e[?9l"          # Turn off mouse reading
	printf "\e[?12l\e[?25h"  # Turn on cursor
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
	
	current_time=$( perl -MTime::HiRes -e 'print int(1000 * Time::HiRes::gettimeofday),"\n"' )
    gravity_elapsed_time=$(($current_time - $gravity_last_update))
    if [[ $gravity_last_update -eq 0 || $gravity_elapsed_time -gt $(( 1000 / $gravity_fps )) ]]; then
        let FB_POS_Y++
        gravity_last_update=$( perl -MTime::HiRes -e 'print int(1000 * Time::HiRes::gettimeofday),"\n"' )
    fi
    
    if [ $FB_POS_Y -ge $FB_HEIGHT ] || [ $FB_POS_Y -le 0 ]]; then
		exit
	fi
	
}

function move() {

	( sleep $TIMING; kill -ALRM $$ ) &

	case "$KEY" in
		' ') let FB_POS_Y-=2 ;;
	esac
	KEY=

	update
	draw_area
	last_update=$( perl -MTime::HiRes -e 'print int(1000 * Time::HiRes::gettimeofday),"\n"' )
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
