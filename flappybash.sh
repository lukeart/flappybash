#!/bin/bash

IFS=''

FB_WIDTH=$(tput cols)
FB_HEIGHT=$(tput lines)

TIMING=0.2

GAP_SIZE=10
MIN_WALL_HEIGHT=5

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
	echo -en "\e[$FB_POS_Y;${FB_POS_X}f$c"
	

}

function update () {
	
	
	current_time=$( perl -MTime::HiRes -e 'print int(1000 * Time::HiRes::gettimeofday),"\n"' )
    gravity_elapsed_time=$(($current_time - $gravity_last_update))
    if [[ $gravity_last_update -eq 0 || $gravity_elapsed_time -gt $(( 1000 / $gravity_fps )) ]]; then
        let FB_POS_Y++
        gravity_last_update=$( perl -MTime::HiRes -e 'print int(1000 * Time::HiRes::gettimeofday),"\n"' )
    fi
}

function move() {
#	check_food
#	if [ $DEATH -gt 0 ] ; then game_over; fi
#	if [ $FOOD_NUMBER -eq 0 ] ; then new_level;	fi

#	echo -en "\e[$HY;${HX}f\e[1;33;42m☻\e[0m"

	( sleep $TIMING; kill -ALRM $$ ) &

	case "$KEY" in
		' ') let FB_POS_Y-=2 ;;
	esac
	KEY=
#	HOUSENKA[$C]="$HY;$HX"
#	: $[C++]	
#	game_info

	update
	draw_area
	last_update=$( perl -MTime::HiRes -e 'print int(1000 * Time::HiRes::gettimeofday),"\n"' )
}

function create_wall() {
	WALL_POS_Y=$(($RANDOM%(FB_HEIGHT-MIN_WALL_HEIGHT-MIN_WALL_HEIGHT-GAP_SIZE)+MIN_WALL_HEIGHT))
	WALL_POS_X=FB_WIDTH
}

function new_level() {
#	unset HOUSENKA
#	for i in ${!FOOD[@]}; do unset FOOD[$i]; done # erase leaves and poison
#	clear
	draw_area
#	FOOD_NUMBER=$[DEFAULT_FOOD_NUMBER*=2]
#	gen_food
#	HX=$[MW/2] HY=$[MH/2]  # start position in the middle of the screen
	# body initialization
#	HOUSENKA=([0]="$[HY-2];$HX" [1]="$[HY-1];$HX" [2]="$HY;$HX") 
	KEY='' 
#	C=2
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
