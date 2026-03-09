#!/bin/bash

# Enableing and disabling hypridle is prolly not the best way to do this but idk... I mostly use the one in waybar anyway.
if pidof hypridle; then
    pkill hypridle
    notify-send "Caffeine Mode ON" "\--hypridle dissabled"
else
    hypridle -c ~/.config/hypr/hypridle.conf &
    notify-send "Caffeine Mode OFF" "\--hypridle enabled"
fi

