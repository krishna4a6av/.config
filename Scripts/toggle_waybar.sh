#!/bin/bash
   
   if pgrep -x "waybar" > /dev/null; then
       killall -9 waybar
       sleep 0.5  # Give it time to fully terminate
   else
       waybar &
   fi
