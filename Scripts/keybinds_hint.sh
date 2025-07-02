#!/usr/bin/env bash

pkill -x rofi && exit
scrDir=$(dirname "$(realpath "$0")")
scrDir="${scrDir:-$HOME/Scripts}"

output="$($scrDir/keybinds.hint.py --format rofi)"

if [ -z "$output" ]; then
  notify-send "Keybind Hint" "Initialization failed."
  exit 0
fi

if ! command -v rofi &>/dev/null; then
  echo "$output"
  echo "rofi not detected. Displaying on terminal instead"
  exit 0
fi

:elected=$(echo -e "$output" | rofi -dmenu -i -theme "clipboard.rasi" -display-columns 1 -display-column-separator ":::")

if [ -z "$selected" ]; then exit 0; fi

dispatch=$(awk -F ':::' '{print $2}' <<<"$selected" | xargs)
arg=$(awk -F ':::' '{print $3}' <<<"$selected" | xargs)
repeat=$(awk -F ':::' '{print $4}' <<<"$selected" | xargs)

# Run the command
RUN() { case "$(eval "hyprctl dispatch '${dispatch}' '${arg}'")" in *"Not enough arguments"*) exec $0 ;; esac }

if [ -n "$dispatch" ] && [ "$(echo "$dispatch" | wc -l)" -eq 1 ]; then
  if [ "$repeat" = repeat ]; then
    while true; do
      repeat_command=$(echo -e "Repeat" | rofi -dmenu -no-custom -p - "[Enter] repeat; [ESC] exit" -theme "notification")
      if [ "$repeat_command" = "Repeat" ]; then
        RUN
      else
        exit 0
      fi
    done
  else
    RUN
  fi
else
  exec $0
fi
