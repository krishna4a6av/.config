#!/bin/bash
   
   if pgrep -x "waybar" > /dev/null; then
       killall waybar
       sleep 0.5  # Give it time to fully terminate
   else
       waybar &
   fi
