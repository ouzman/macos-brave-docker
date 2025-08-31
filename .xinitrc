#!/bin/sh
export PATH="/opt/X11/bin:$PATH"

xhost + 127.0.0.1

/opt/X11/bin/setxkbmap -rules base -model pc105 -layout tr -option ''

[ -f "$HOME/.Xmodmap" ] && /opt/X11/bin/xmodmap "$HOME/.Xmodmap"

exec /opt/X11/bin/quartz-wm
