#!/bin/bash

# Function to generate a new apple position within the game area
generate_apple() {
   while : ; do
      APPLEX=$(( (RANDOM % (AREAMAXX - AREAMINX + 1)) + AREAMINX ))
      APPLEY=$(( (RANDOM % (AREAMAXY - AREAMINY + 1)) + AREAMINY ))
      local in_use=false
      for ((x = 0; x < ${#SNAKE_POSX[@]}; x++)); do
         if [[ "$APPLEX" == "${SNAKE_POSX[$x]}" && "$APPLEY" == "${SNAKE_POSY[$x]}" ]]; then
            in_use=true
            break
         fi
      done
      if [[ "$in_use" == false ]]; then
         break
      fi
   done
}

# Function to draw the apple on the board
draw_apple() {
   tput setaf 1
   tput cup $APPLEY $APPLEX
   printf "%b" "$APPLECHAR"
   tput setaf 7
}

# Function to grow the snake
grow_snake() {
   local tail_x=${SNAKE_POSX[-1]}
   local tail_y=${SNAKE_POSY[-1]}
   SNAKE_POSX+=("$tail_x")
   SNAKE_POSY+=("$tail_y")
}

# Function to move the snake in the current direction
move_snake() {
   case "$DIRECTION" in
    u) POSY=$((POSY - 1))
        # Check and adjust outside top wall
        if [[ $POSY -lt $FIRSTROW ]]; then
          POSY=$FIRSTROW
        fi
        ;;
    d) POSY=$((POSY + 1))
        # Check and adjust outside bottom wall
        if [[ $POSY -gt $LASTROW ]]; then
          POSY=$LASTROW
        fi
        ;;
    l) POSX=$((POSX - 1))
        # Check and adjust  outside left wall
        if [[ $POSX -lt $FIRSTCOL ]]; then
          POSX=$FIRSTCOL
        fi
        ;;
    r) POSX=$((POSX + 1))
        # Check and adjust outside right wall
        if [[ $POSX -gt $LASTCOL ]]; then
          POSX=$LASTCOL
        fi
        ;;
  esac

   # Collision detection with walls
   if [[ $POSX -le $FIRSTCOL || $POSX -ge $LASTCOL || $POSY -le $FIRSTROW || $POSY -ge $LASTROW ]]; then
      game_over "You hit a wall!"
   fi

   # Collision detection with itself
   for ((i = 1; i < ${#SNAKE_POSX[@]}; i++)); do
      if [[ $POSX == ${SNAKE_POSX[$i]} && $POSY == ${SNAKE_POSY[$i]} ]]; then
         game_over "You ate yourself!"
      fi
   done

   # Clear the tail
   tput cup ${SNAKE_POSY[0]} ${SNAKE_POSX[0]}
   printf " "

   # Update snake positions
   SNAKE_POSX=("${SNAKE_POSX[@]:1}" "$POSX")
   SNAKE_POSY=("${SNAKE_POSY[@]:1}" "$POSY")

   # Draw the snake
   for ((i = 0; i < ${#SNAKE_POSX[@]}; i++)); do
      tput setaf 2
      tput cup ${SNAKE_POSY[$i]} ${SNAKE_POSX[$i]}
      if [[ $i -eq $((${#SNAKE_POSX[@]} - 1)) ]]; then
         printf "%b" "$SNAKECHAR"
      else
         printf "%b" "$BODYCHAR"
      fi
   done
   tput setaf 7

   # Check if apple is eaten
   if [[ $POSX -eq $APPLEX && $POSY -eq $APPLEY ]]; then
      grow_snake
      update_score 10
      generate_apple
      draw_apple
   fi
}

# Function to update the score
update_score() {
   SCORE=$((SCORE + $1))
   tput cup 2 45
   printf "SCORE: %d" "$SCORE"
}

# Function to handle game over
game_over() {
   tput cvvis
   stty echo
   local message="$1"
   tput cup 4 45
   printf "GAME OVER! %s\n" "$message"
   tput cup 5 45
   printf "FINAL SCORE: %d\n" "$SCORE"
   tput cup 6 45
   printf "Press 'r' to restart or any other key to exit..."
   read -n 1 -s key
   if [[ "$key" == "r" ]]; then
      main
   else
      tput cup 7 45
      printf "EXITED..."
      read -n 1 -s
      tput cup $ROWS 0
      exit 0
   fi
}

# Function to draw the border
draw_border() {
    tput setaf 6
  # Draw top and bottom borders
  for ((x = FIRSTCOL; x <= LASTCOL; x++)); do
    tput cup $LASTROW   $x; printf "%b" "$WALLCHAR"
    tput cup $FIRSTROW  $x; printf "%b" "$WALLCHAR"
  done
  # Draw left and right borders
  for ((y = FIRSTROW + 1; y <= LASTROW - 1; y++)); do
    tput cup $y $FIRSTCOL; printf "%b" "$WALLCHAR"
    tput cup $y $LASTCOL; printf "%b" "$WALLCHAR"
  done
  tput setaf 6
}

# Function to reset terminal settings on exit

# Function to choose the difficulty level
choose_level() {
   clear
   printf "
Choose difficulty level:
1 - Easy
2 - Medium
3 - Hard

Press the corresponding number to choose the level.
"
   read -n 1 -s level
   case "$level" in
      1) DELAY=0.3 ;;
      2) DELAY=0.2 ;;
      3) DELAY=0.1 ;;
      *) DELAY=0.3 ;;
   esac
}

# Main game loop
main() {
   choose_level
   tput civis
   stty -echo
   clear
   printf "
Keys:

 W - UP
 S - DOWN
 A - LEFT
 D - RIGHT
 X - QUIT

Press Enter to continue
"
   read -s -n 1
   clear

   # Initialize game variables
   SNAKECHAR="@"
   BODYCHAR="*"
   WALLCHAR="#"
   APPLECHAR="o"
   FIRSTROW=1
   FIRSTCOL=1
   LASTCOL=40
   LASTROW=20
   AREAMAXX=$((LASTCOL - 1))
   AREAMINX=$((FIRSTCOL + 1))
   AREAMAXY=$((LASTROW - 1))
   AREAMINY=$((FIRSTROW + 1))
   ROWS=$(tput lines)
   ORIGINX=$((LASTCOL / 2))
   ORIGINY=$((LASTROW / 2))
   POSX=$ORIGINX
   POSY=$ORIGINY
   SNAKE_POSX=($POSX $POSX $POSX)
   SNAKE_POSY=($POSY $POSY $POSY)
   SCORE=0
   DIRECTION="r"

   # Draw the border and initial apple
   draw_border
   update_score 0
   generate_apple
   draw_apple

   # Main game loop
   while : ; do
      read -s -n 1 -t $DELAY key
      case "$key" in
         w) [[ "$DIRECTION" != "d" ]] && DIRECTION="u" ;;
         s) [[ "$DIRECTION" != "u" ]] && DIRECTION="d" ;;
         a) [[ "$DIRECTION" != "r" ]] && DIRECTION="l" ;;
         d) [[ "$DIRECTION" != "l" ]] && DIRECTION="r" ;;
         x) game_over "Quitting..." ;;
      esac
      move_snake
   done
}

main
