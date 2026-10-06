#!/usr/bin/env bash
# Create and attach the custom 1920x1080@60 mode on DisplayPort-2 for 2x2 1920x1080 monitor layout on dell dock
xrandr --newmode "1920x1080_60.00" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
xrandr --addmode DisplayPort-2 1920x1080_60.00
